# Painel React com Vite — desenho

## Objetivo

Migrar integralmente a tela `/painel` para React, mantendo Rails como a aplicação proprietária de sessão, autorização, regras de negócio e dados. A primeira adoção de React deve ser isolada ao Painel; todas as demais telas continuam ERB + Hotwire.

O novo Painel será uma central de comando operacional: visual escuro, alto contraste e prioridade explícita para itens que exigem ação imediata. Toda alteração feita no Painel deve ocorrer sem recarregar a página.

## Escopo

Incluído:

- Toda a área de conteúdo do Painel: ação prioritária, KPIs, filas críticas, feed de andamentos, distribuição e gráficos.
- Integração React compilada por Vite dentro do monólito Rails.
- Uma interface JSON autenticada e limitada ao Painel.
- Atualização assíncrona das ações existentes de atribuição de responsável, próxima providência, justificativa de prazo, responsável de tarefa e sincronização de andamentos.
- Atualização imediata da tela após uma ação bem-sucedida: o item deixa a fila quando não se aplica mais, contadores e dados relacionados são atualizados e uma confirmação breve é exibida.
- Estados de carregamento, falha e vazio acessíveis.

Fora de escopo:

- Migrar outras rotas ou layouts para React.
- Criar um frontend Next.js separado.
- Alterar regras de negócio, escopos de escritório/unidade ou permissões já aplicadas pelo Rails.
- Alterar o mecanismo de sincronização CNJ; o Painel apenas dispara o job existente.

## Arquitetura

Vite passa a ser o adaptador de build do React. A view ERB de `/painel` continua mínima: preserva o layout Rails, a seleção obrigatória de unidade e um elemento de montagem para o React. Quando a unidade estiver selecionada, o bundle React monta a aplicação do Painel nesse elemento.

O Rails expõe um módulo profundo de apresentação do Painel: uma resposta JSON autenticada fornece todos os dados necessários para renderizá-lo. O React conhece somente esse contrato; não consulta modelos, não reproduz regras de escopo e não interpreta permissões. Essa é a seam entre os dois lados.

```
Browser
  └─ React Dashboard (estado visual e interação)
       ├─ GET /painel.json
       └─ PATCH/POST ações existentes com Accept: application/json
              └─ Rails DashboardController
                   ├─ sessão e current_office/current_unit
                   ├─ autorizações e validações existentes
                   ├─ consultas e TimelineBuilder existentes
                   └─ JSON do Painel atualizado
```

Após cada mutação bem-sucedida, o cliente solicita novamente o snapshot JSON do Painel. Isso prioriza correção e localidade: a regra de quando um item sai de uma fila permanece no Rails, e o React recebe uma visão consistente em vez de implementar contadores e filtros duplicados.

## Interface JSON

`GET /painel.json` retorna um snapshot completo, apenas para usuário autenticado e no mesmo escopo de escritório/unidade da página HTML. A forma proposta é:

```json
{
  "meta": {
    "unitSelectionRequired": false,
    "unitName": "Unidade Centro",
    "syncableCount": 12,
    "newImportedEventsCount": 2
  },
  "priorityAction": null,
  "kpis": {},
  "criticalQueues": {},
  "riskQueue": {},
  "feed": [],
  "distribution": { "phase": [], "status": [] },
  "actions": {
    "sync": "/painel/sync",
    "updateResponsible": "/painel/processos/:id/responsavel",
    "updateNextAction": "/painel/processos/:id/providencia",
    "updateDeadlineReason": "/painel/prazos/:id/justificativa",
    "updateTaskResponsible": "/painel/tarefas/:id/responsavel"
  }
}
```

O formato final será tipado em TypeScript e serializado explicitamente no Rails; nomes, links e valores apresentados não serão montados diretamente a partir de atributos não tratados.

As ações existentes passam a responder JSON quando solicitadas com `Accept: application/json`:

- sucesso: `200` com uma mensagem e, quando útil, o registro atualizado;
- entrada inválida: `422` com mensagem exibível;
- acesso inexistente ou escopo inválido: resposta de erro do Rails, sem vazar dados;
- sincronização enfileirada: `202` com a mensagem de confirmação.

As respostas HTML e redirecionamentos existentes permanecem para chamadas fora do React.

O cliente inclui o token CSRF emitido pelo layout Rails em toda mutação. Não há token de API separado, nem sessão fora do Rails.

## Experiência do Painel

### Estrutura

1. Cabeçalho operacional com contexto de unidade, ação de sincronização e acesso às ações já existentes de criação.
2. Bloco de próxima ação e resumo de urgências: prazos de hoje, processos em risco e tarefas de hoje.
3. Fila de atenção com processos sem responsável, sem próxima providência, prazos vencidos sem justificativa e central de risco.
4. Feed de andamentos recentes e atualização CNJ.
5. Distribuição por fase e gráficos de fase/status.

O tema é escuro, com superfícies azul-marinho, alto contraste de texto e cores semânticas reservadas a estados: amarelo para atenção, vermelho para risco e azul para ações ou informação. O conteúdo nunca depende somente de cor: cada estado inclui texto, ícone ou contagem.

### Estados assíncronos

Cada ação desabilita somente seu próprio controle enquanto é enviada. Em sucesso, a interface exibe uma notificação breve e busca um novo snapshot; o item resolvido desaparece da fila caso deixe de satisfazer o critério. Em falha, o conteúdo visível não é substituído e uma mensagem explica a ação necessária.

O carregamento inicial usa esqueletos nas áreas principais. Estados vazios continuam explicando que não há pendência, em vez de deixar espaços em branco. Se a seleção de unidade for obrigatória, a view Rails mantém o diálogo atual e o React não é montado.

## Módulos React

- `DashboardApp`: coordena snapshot, atualização e notificações.
- `DashboardApi`: único adaptador HTTP; centraliza CSRF, JSON, erros e URLs.
- `DashboardHeader` e `PriorityAction`: contexto e foco imediato.
- `KpiGrid`: indicadores clicáveis para as listagens Rails já existentes.
- `CriticalQueues` e `RiskCenter`: filas e formulários assíncronos.
- `RecentActivityFeed`: timeline recente com links para processos.
- `Distribution`: cartões de fase e gráficos.
- `ToastRegion`, `LoadingState` e `ErrorState`: feedback transversal e acessível.

Os módulos recebem dados tipados e callbacks estreitos. Eles não fazem consultas próprias, não conhecem o banco e não duplicam decisões de filtragem do controller.

## Testes

- Testes de request Rails para o snapshot JSON, escopo de escritório/unidade, CSRF e os resultados JSON de cada mutação.
- Testes de componente React para carregamento, vazio, erro, renderização de contagens e feedback de sucesso.
- Testes de integração do fluxo: editar uma pendência, receber sucesso, buscar snapshot atualizado e confirmar a remoção do item/atualização dos contadores.
- Teste de sistema para o caminho principal em `/painel` com JavaScript habilitado.

## Critérios de aceite

- `/painel` apresenta a nova central de comando React sem afetar outras telas Rails.
- Todos os dados atualmente exibidos no Painel continuam disponíveis no novo desenho.
- Todas as ações atualmente disponíveis no Painel funcionam sem recarregar a página.
- O Rails continua validando e limitando cada leitura e escrita ao escritório/unidade do usuário.
- O usuário vê confirmação de sucesso e mensagem acionável em caso de erro.
- Após uma mutação bem-sucedida, filas, KPIs e gráficos refletem o snapshot atual do servidor.
