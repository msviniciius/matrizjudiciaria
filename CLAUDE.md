# CLAUDE.md

## Projeto: Matriz Jurídica

Sistema de gestão jurídica para escritórios de advocacia — controle de processos, clientes, prazos, tarefas, andamentos, perícias, movimentações processuais e calendário.

**Diferencial principal**: atualização automática dos andamentos processuais via integração com a API do PJe MA. Em vez de o advogado consultar manualmente cada processo no sistema do tribunal, o Matriz Jurídica busca os andamentos automaticamente e os registra como `CaseEvent`, mantendo tudo sincronizado.

## Stack

- **Ruby**: 3.4.0
- **Rails**: 8.1.2
- **Banco**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Importmap, Propshaft
- **Jobs**: Solid Queue
- **Cache**: Solid Cache
- **Cable**: Solid Cable
- **PDF**: Prawn
- **Deploy**: Kamal + Docker
- **Autenticação**: Sessões próprias (não usa Devise) — `SessionsController`, model `User`
- **Ambiente**: Dotenv (`.env` no desenvolvimento)

## Modelos principais

| Modelo | Descrição |
|---|---|
| `LegalCase` | Processo judicial — entidade central |
| `Client` | Cliente do escritório |
| `Court` | Vara/Tribunal |
| `District` | Comarca/Seção judiciária |
| `Deadline` | Prazo processual |
| `DeadlineSetting` | Configuração de prazos por tipo |
| `Task` | Tarefa interna do escritório |
| `CaseEvent` | Andamento/evento do processo |
| `ProcessExam` | Perícia vinculada a um processo |
| `ProcessMovement` | Movimentação processual |
| `MovementType` | Tipo de movimentação |
| `MovementTemplate` | Template de movimentação |
| `User` | Usuário do sistema |
| `Office` | Configuração do escritório (`OfficeSetting`) |
| `LegalArea` | Área do direito |
| `ProcessType` | Tipo de processo |
| `ProcessPhase` | Fase processual |
| `ProcessStatus` | Status do processo |

## Controllers e rotas

Rotas definidas em `config/routes.rb`. Destaques:
- **Root**: `dashboard#index` (`/painel`)
- **Autenticação**: `/login`, `/logout` → `sessions#new`, `sessions#create`, `sessions#destroy`
- **Calendário**: `/calendario_interno` → `internal_calendars#index`; feeds iCal em `/calendar_feeds/legal_case/:token.ics`
- **PDF**: `legal_cases/:id/pdf`, `legal_cases/:id/print`
- **Google Calendar**: `legal_cases/:id/google_calendar`
- **Quick actions** no painel: PATCH para responsável, providência, justificativa de prazo, responsável de tarefa

## Seeds e ambiente

- Nome do escritório padrão: `"Kayran Advocacia"` (definido em `.env` via `OFFICE_NAME`)
- Admin padrão: `admin@matrizjuridica.com` / `admin123`

### Integração CNJ DataJud (atualização automática de andamentos) — IMPLEMENTADO

O sistema usa a **API pública do CNJ DataJud** (não o PJe MA direto) para buscar automaticamente os andamentos. A API DataJud agrega dados de todos os tribunais brasileiros. Estamos usando o endpoint do TJMA (`api_publica_tjma/_search`).

**Como funciona:**
1. O job `Pje::Ma::ImportCaseEventsJob` pega todos os `LegalCase` com `external_number` preenchido e status operacional
2. Para cada processo, consulta o CNJ DataJud por `numeroProcesso`
3. Os movimentos já vêm dentro do documento do processo (`_source.movimentos[]`)
4. O normalizer `PjeMaCaseEventNormalizer` mapeia cada movimento CNJ → `CaseEvent`
5. Deduplicação via `pje_external_id` (índice único condicional) — se o andamento já existe, pula
6. Ao final, atualiza `last_synced_at` no `LegalCase`

| Arquivo | O que faz |
|---|---|
| `app/services/pje/cnj/client.rb` | Cliente HTTP para API DataJud (ApiKey auth, timeout 60s) |
| `app/services/pje/base_client.rb` | Cliente HTTP genérico com timeouts configuráveis |
| `app/services/pje/ma/client.rb` | Cliente PJe MA legado (credenciais vazias, substituído pelo CNJ) |
| `app/services/pje/ma/importer.rb` | Importador legado (substituído pela lógica direta no job) |
| `app/services/integrations/normalizers/pje_ma_case_event_normalizer.rb` | Mapeia JSON do CNJ → atributos do CaseEvent |
| `app/jobs/pje/ma/import_case_events_job.rb` | Job principal de sincronização |
| `config/recurring.yml` | Agendamento a cada 30min (prod) / 2h (dev) |
| `lib/tasks/pje_ma.rake` | Tarefas rake `pje:ma:inspect_cnj` e `pje:ma:inspect_api` |

**Formato da resposta CNJ DataJud (confirmado via teste real):**
```json
{
  "_source": {
    "numeroProcesso": "08004664120258100030",
    "tribunal": "TJMA",
    "dataHoraUltimaAtualizacao": "2026-07-10T03:46:59.965000Z",
    "movimentos": [
      {
        "codigo": 1051,
        "dataHora": "2026-02-07T01:08:49.000Z",
        "nome": "Decurso de Prazo",
        "complementosTabelados": [{"codigo": 3, "nome": "para despacho"}],
        "orgaoJulgador": {"codigo": "3134", "nome": "JUIZADO ESPECIAL..."}
      }
    ]
  }
}
```

**Credenciais configuradas no `.env`:**
- `CNJ_PJE_BASE_URL` = `https://api-publica.datajud.cnj.jus.br`
- `CNJ_PJE_API_KEY` = (configurado)
- `CNJ_PJE_TRIBUNAL_ALIAS` = `tjma`

**Campos novos no banco** (migrations criadas, pendentes de execução):
- `case_events.pje_external_id` (string, índice único condicional) — chave de deduplicação
- `case_events.event_date` (datetime) — data real do evento no tribunal
- `legal_cases.pje_case_id` (string) — ID interno do CNJ para o processo
- `legal_cases.last_synced_at` (datetime) — última sincronização bem-sucedida

**Para rodar a sincronização manualmente:**
```bash
bin/rails runner "Pje::Ma::ImportCaseEventsJob.perform_now"
# Ou para um caso específico:
bin/rails runner "Pje::Ma::ImportCaseEventsJob.perform_now(legal_case_ids: [1,2,3])"
```

## Onde paramos

Branch atual: `main`

Últimos commits de desenvolvimento (antes dos bumps de dependências):
- `f73191c` — Refina fluxo de perícia no processo e padroniza toggles nos formulários
- `a58aa59` — Simplifica case events e remove campos legados de evento
- `0332eb1` — Ajusta fluxo de perícia no processo e simplifica andamento
- `6fed515` — Ajusta responsáveis e melhora listagens de andamentos
- `4015d5e` — Padroniza telas de operação e ajustes de rotas/controladores
- `2ce7980` — Melhora UX dos formulários e simplifica pendências críticas no painel

Trabalho recente focado em:
- **Perícias** (process exams): fluxo dentro do processo, formulários
- **Andamentos** (case events): simplificação, remoção de campos legados
- **Padronização**: toggles nos formulários, telas de operação
- **UX**: formulários, painel de pendências, responsáveis

Os branches `dependabot/*` são bumps automáticos de dependências via GitHub Actions.

## Comandos úteis

```bash
cd Documentos/matrizjuridica

# Iniciar servidor
bin/rails server

# Console
bin/rails console

# Testes
bin/rails test
bin/rails test:system

# Migrations
bin/rails db:migrate
bin/rails db:seed

# Rotas
bin/rails routes
```
