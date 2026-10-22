# Integração de prazos por expediente Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer prazos judiciais nascerem de expedientes e ciência, calculando automaticamente datas úteis e exibindo o resultado no módulo atual de prazos.

**Architecture:** Reutilizar `LegalCase` e `Deadline`, adicionando `Expediente`, `Ciencia`, `Feriado` e `Suspensao`. Deadlines sem expediente permanecem manuais; deadlines vinculados a expediente têm datas calculadas por serviços de domínio e são atualizados pelo job diário do Solid Queue.

**Tech Stack:** Ruby on Rails 8, PostgreSQL, Active Job/Solid Queue, React/TypeScript, Minitest.

**Spec:** `docs/superpowers/specs/2026-10-21-integracao-prazos-expedientes-design.md`

## Global Constraints

- Manter os nomes e padrões já existentes no repositório quando divergirem do documento original.
- Usar serviços em `app/services/`; não colocar cálculo de prazo em controller ou callback complexo de model.
- Manter deadlines existentes sem expediente funcionando.
- Respeitar escopo por escritório e unidade em queries, controllers, jobs e snapshots.
- Não adicionar gem externa obrigatória.
- Usar Minitest, que é o framework presente no projeto.
- Definir o timezone de negócio antes de depender de cálculos com `Date.current`.

## Review Focus

- Deadline manual sem expediente: deve continuar podendo ser criado e editado como hoje; cobrir em `test/controllers/deadlines_controller_test.rb`.
- Expediente sem ciência: deve criar deadline sem datas calculadas e sem permitir vencimento fictício; cobrir em `test/models/expediente_test.rb` e `test/services/deadline_calculator_test.rb`.
- Ciência em fim de semana, feriado ou recesso: o termo inicial deve avançar para o primeiro dia útil; cobrir em `test/services/business_days_calculator_test.rb`.
- Prazo corrido com vencimento não útil: deve ajustar somente o vencimento para o próximo dia útil; cobrir em `test/services/deadline_calculator_test.rb`.
- Dados de outro escritório/unidade: não podem aparecer, ser alterados ou ser processados pelo usuário/job atual; cobrir em controllers e `test/jobs/refresh_prazos_job_test.rb`.

### Task 1: Preparar timezone e entidades de calendário

**Files:**
- Modify: `config/application.rb`
- Create: `db/migrate/20261021010000_create_feriados.rb`
- Create: `db/migrate/20261021010100_create_suspensoes.rb`
- Create: `app/models/feriado.rb`
- Create: `app/models/suspensao.rb`
- Create: `test/models/feriado_test.rb`
- Create: `test/models/suspensao_test.rb`

**Interfaces:**
- Produces `Feriado` com `data`, `descricao`, `ambito` e escopo definido para o modelo multi-escritório.
- Produces `Suspensao` com `inicio`, `fim`, `descricao` e validação de intervalo.

- [ ] **Step 1: Escrever testes de validação** para datas obrigatórias, intervalo inválido e valores de `ambito`.
- [ ] **Step 2: Rodar os testes** com `bin/rails test test/models/feriado_test.rb test/models/suspensao_test.rb` e confirmar falha por modelos/tabelas ausentes.
- [ ] **Step 3: Configurar `config.time_zone`** para o timezone definido na especificação e criar as migrations/modelos com índices para data e intervalo.
- [ ] **Step 4: Rodar os testes** e confirmar PASS.
- [ ] **Step 5: Commitar** com `git add config/application.rb db/migrate app/models test/models && git commit -m "feat: add legal calendar entities"`.

### Task 2: Implementar cálculo de dias úteis

**Files:**
- Create: `app/services/business_days_calculator.rb`
- Create: `test/services/business_days_calculator_test.rb`

**Interfaces:**
- `BusinessDaysCalculator.new(reference_date: Date.current, office: nil, legal_case: nil)`
- `#dia_util?(date) -> Boolean`
- `#proximo_dia_util(date) -> Date`
- `#somar_dias_uteis(date, number) -> Date`
- `#dias_uteis_entre(start_date, end_date) -> Integer`

- [ ] **Step 1: Escrever testes** para fim de semana, feriado, suspensão/recesso, soma cruzando feriado e contagem de intervalo.
- [ ] **Step 2: Rodar** `bin/rails test test/services/business_days_calculator_test.rb` e confirmar falha.
- [ ] **Step 3: Implementar** carregando feriados e suspensões uma vez por instância/cálculo e tratando intervalos inclusivamente conforme a regra do domínio.
- [ ] **Step 4: Rodar os testes** e confirmar PASS.
- [ ] **Step 5: Commitar** com `git add app/services/business_days_calculator.rb test/services/business_days_calculator_test.rb && git commit -m "feat: calculate legal business days"`.

### Task 3: Criar expediente e ciência

**Files:**
- Create: `db/migrate/20261021020000_create_expedientes.rb`
- Create: `db/migrate/20261021020100_create_ciencias.rb`
- Create: `app/models/expediente.rb`
- Create: `app/models/ciencia.rb`
- Modify: `app/models/legal_case.rb`
- Create: `test/models/expediente_test.rb`
- Create: `test/models/ciencia_test.rb`

**Interfaces:**
- `LegalCase has_many :expedientes`.
- `Expediente belongs_to :legal_case`, `has_one :ciencia`, `has_one :deadline`.
- `Ciencia belongs_to :expediente` e opcionalmente `belongs_to :user`.
- Expediente terá enums para tipo, contagem e origem; ciência terá enum expressa/tácita.

- [ ] **Step 1: Escrever testes** para associações, validações, unicidade de ciência por expediente e criação do deadline jurídico pendente.
- [ ] **Step 2: Rodar** `bin/rails test test/models/expediente_test.rb test/models/ciencia_test.rb` e confirmar falha.
- [ ] **Step 3: Implementar** migrations, associações, enums e criação transacional do deadline aguardando ciência.
- [ ] **Step 4: Rodar os testes** e confirmar PASS.
- [ ] **Step 5: Commitar** com `git add db/migrate app/models test/models && git commit -m "feat: add legal expedients and acknowledgements"`.

### Task 4: Evoluir Deadline e calcular datas jurídicas

**Files:**
- Create: `db/migrate/20261021030000_add_expediente_fields_to_deadlines.rb`
- Modify: `app/models/deadline.rb`
- Create: `app/services/deadline_calculator.rb`
- Create: `test/models/deadline_test.rb` (adicionar casos)
- Create: `test/services/deadline_calculator_test.rb`

**Interfaces:**
- `Deadline belongs_to :expediente, optional: true`.
- `DeadlineCalculator.new(deadline, today: Date.current).recalcular! -> Deadline`.
- `Deadline#cumprir!(protocolo_ref: nil)` deverá preservar a conclusão existente e aceitar protocolo quando o prazo for jurídico.

- [ ] **Step 1: Escrever testes** para termo inicial após ciência, dias úteis, dias corridos ajustados, prazo em dobro, sem ciência e transições para vencendo/vencido.
- [ ] **Step 2: Rodar** `bin/rails test test/services/deadline_calculator_test.rb test/models/deadline_test.rb` e confirmar falha.
- [ ] **Step 3: Implementar** a migration e o serviço; deadlines sem expediente devem seguir o caminho atual.
- [ ] **Step 4: Ajustar o controller/modelo** para impedir edição manual de `due_date` em deadline jurídico, mantendo edição dos demais campos permitidos.
- [ ] **Step 5: Rodar os testes** e confirmar PASS.
- [ ] **Step 6: Commitar** com `git add db/migrate app/models app/services test/models test/services app/controllers && git commit -m "feat: calculate deadlines from expedients"`.

### Task 5: Adicionar ciência expressa e cumprimento pela interface

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/expedientes_controller.rb` ou ação equivalente no fluxo existente
- Create: `app/controllers/ciencias_controller.rb`
- Modify: `app/controllers/deadlines_controller.rb`
- Modify: views/snapshot do detalhe de deadline e processo
- Modify: testes de controllers existentes

**Interfaces:**
- `POST /expedientes` cria expediente dentro do escopo do escritório.
- `POST /ciencias` registra ciência expressa e chama `DeadlineCalculator`.
- `PATCH /deadlines/:id/cumprir` conclui o deadline com `protocolo_ref` opcional.

- [ ] **Step 1: Escrever testes de controller** para criar expediente, dar ciência, cumprir prazo e rejeitar registros de outro escritório.
- [ ] **Step 2: Rodar os testes** e confirmar falha por rotas/controllers ausentes.
- [ ] **Step 3: Implementar controllers, rotas e respostas HTML/JSON** seguindo os padrões de autenticação, escopo e `params.expect` existentes.
- [ ] **Step 4: Exibir ações** de criar expediente, dar ciência e cumprir prazo nos pontos atuais de detalhe/listagem.
- [ ] **Step 5: Rodar os testes** e confirmar PASS.
- [ ] **Step 6: Commitar** com `git add config/routes.rb app/controllers app/views test/controllers && git commit -m "feat: manage expedients and deadline acknowledgement"`.

### Task 6: Criar job diário e seeds de calendário

**Files:**
- Create: `app/jobs/refresh_prazos_job.rb`
- Modify: `config/recurring.yml`
- Modify: `db/seeds.rb`
- Create: `test/jobs/refresh_prazos_job_test.rb`

**Interfaces:**
- `RefreshPrazosJob.perform` processa deadlines jurídicos em aberto e cria ciência tácita após o prazo de leitura configurado.
- O job deve aceitar escopo opcional por `office_id` para testes e reprocessamento seguro.

- [ ] **Step 1: Escrever testes** para ciência tácita, atualização de estados, idempotência e isolamento por escritório.
- [ ] **Step 2: Rodar** `bin/rails test test/jobs/refresh_prazos_job_test.rb` e confirmar falha.
- [ ] **Step 3: Implementar** o job usando `DeadlineCalculator` e consultas em lote; não recalcular deadlines manuais.
- [ ] **Step 4: Adicionar seeds idempotentes** para feriados nacionais, estaduais/forenses do Maranhão e recesso de 20/12 a 20/01.
- [ ] **Step 5: Agendar** o job no `config/recurring.yml` para produção e desenvolvimento.
- [ ] **Step 6: Rodar testes do job e seeds** e confirmar PASS.
- [ ] **Step 7: Commitar** com `git add app/jobs config/recurring.yml db/seeds.rb test/jobs && git commit -m "feat: refresh legal deadlines daily"`.

### Task 7: Adaptar snapshots, dashboard e calendário

**Files:**
- Modify: `app/controllers/deadlines_controller.rb`
- Modify: `app/presenters/deadlines_snapshot.rb`
- Modify: `app/presenters/dashboard_snapshot.rb`
- Modify: `app/controllers/internal_calendars_controller.rb`
- Modify: `app/frontend/deadlines/DeadlinesApp.tsx`
- Modify: `app/frontend/deadlines/deadlines.css`
- Modify: testes de presenters/controllers/frontend existentes

**Interfaces:**
- O snapshot de deadlines deverá expor estado jurídico, origem, data de ciência e expediente quando disponíveis.
- O painel deverá oferecer caixas para aguardando ciência, em curso, vencendo, vencidos e concluídos recentes, sem remover filtros atuais.

- [ ] **Step 1: Escrever testes** para agrupamento/contagem, ordenação por vencimento, concluídos nos últimos 10 dias e preservação de deadlines manuais.
- [ ] **Step 2: Rodar testes de presenters/controllers/frontend** e confirmar falha nos novos campos.
- [ ] **Step 3: Ajustar queries e presenters** para usar `Deadline` como fonte única e respeitar unidade/escritório.
- [ ] **Step 4: Implementar as caixas no React** reaproveitando o layout e estilos atuais.
- [ ] **Step 5: Confirmar calendário e dashboard** com deadlines jurídicos e manuais.
- [ ] **Step 6: Rodar a suíte relacionada** e confirmar PASS.
- [ ] **Step 7: Commitar** com `git add app/controllers app/presenters app/frontend test && git commit -m "feat: show legal deadline states"`.

### Task 8: Verificação final e documentação operacional

**Files:**
- Modify: documentação operacional existente, se necessário
- Modify: testes de integração do fluxo completo

- [ ] **Step 1: Adicionar teste de integração** cobrindo expediente → ciência → cálculo → painel.
- [ ] **Step 2: Rodar a suíte Rails completa** com `bin/rails test`.
- [ ] **Step 3: Rodar testes frontend** com o comando definido no `package.json`.
- [ ] **Step 4: Rodar lint/formatters já configurados** sem introduzir novas ferramentas.
- [ ] **Step 5: Verificar migrations, seeds e recorrência** em ambiente de teste.
- [ ] **Step 6: Revisar segurança por escritório/unidade e alterações no Git**.
- [ ] **Step 7: Commitar** somente os arquivos da integração listados no diff, sem usar `git add .`, com `git commit -m "test: verify legal deadline workflow"`.

## Ordem de execução

Executar as tarefas em ordem. Cada tarefa deve terminar com seus testes passando antes da próxima. As integrações automáticas DJMA/PJe e alertas por e-mail ficam fora deste plano até o fluxo manual estar validado em produção de teste.

