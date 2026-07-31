# Final fixes report

Status: concluído.

## Achados corrigidos

1. Critical — escopo dos KPIs:
   - `DeadlinesController#index` e `TasksController#index` agora aplicam a unidade ativa por meio de `ApplicationController#scope_by_current_unit`.
   - A unidade continua sendo determinada pelo contexto Rails (`current_unit`/sessão); nenhum parâmetro de unidade passou a ser aceito pelo frontend.
   - Regressões cobrem a exclusão de registros pertencentes a outra unidade nas duas listas.
2. Important — detalhe read-only:
   - Removido o `touch(:last_viewed_events_at)` de `LegalCasesController#show`.
   - A renderização HTML não altera mais o processo e o snapshot React preserva `has_new_imported_events`.
3. Important — Vite por ação:
   - O layout carrega `dashboard.tsx` somente em `dashboard#index`, `legal_cases.tsx` somente em `legal_cases#index` e `legal_case_show.tsx` somente em `legal_cases#show`.
   - Outras ações de `LegalCasesController` não carregam client, refresh ou entrypoints Vite.
4. Important — limite da sincronização:
   - `DashboardController#sync_all` passa `limit` igual ao número de IDs filtrados e anunciado ao usuário.
5. Important — landmarks:
   - As raízes de `DashboardApp` e `LegalCasesApp` agora são `div`, reutilizando o único landmark `main` fornecido pelo layout Rails.
6. Minor — IDs da timeline:
   - `TimelineBuilder` inclui `process_movement_id` e `case_event_id` nos itens detalhados.
   - `LegalCaseShowSnapshot` passa a emitir IDs numéricos, estáveis e não nulos para ambas as origens.

## Ciclo RED → GREEN

Antes das mudanças de produção, foram adicionadas regressões para todos os itens críticos/importantes e executadas contra o código anterior:

- Frontend RED: 2 falhas esperadas, ambas mostrando dois elementos `main`.
- Rails RED: falhas esperadas para vazamento entre unidades, mutação de `last_viewed_events_at`, ausência de `limit` no job e IDs `nil` na timeline. A ação `new` também tentou resolver indevidamente o entrypoint Vite, comprovando o carregamento fora de escopo.

Depois das correções:

- `PARALLEL_WORKERS=1 bin/rails test test/controllers/deadlines_controller_test.rb test/controllers/tasks_controller_test.rb test/controllers/legal_cases_controller_test.rb test/controllers/dashboard_controller_test.rb test/presenters/legal_case_show_snapshot_test.rb`
  - 52 testes, 155 asserções, 0 falhas, 0 erros.
- `PARALLEL_WORKERS=1 bin/rails test`
  - 110 testes, 316 asserções, 0 falhas, 0 erros.
- `npm test`
  - 3 arquivos, 25 testes, todos aprovados.
- `npx tsc --noEmit --jsx react-jsx --moduleResolution bundler --module preserve --target ES2022 --lib ES2022,DOM,DOM.Iterable --types vite/client app/frontend/dashboard/DashboardApp.tsx app/frontend/legal_cases/LegalCasesApp.tsx`
  - exit 0.
  - O projeto não possui `tsconfig.json`; por isso a checagem usou opções e arquivos explícitos.
- `bin/vite build`
  - build de produção concluído, 23 módulos transformados.
- `git diff --check`
  - sem erros.

## Commits

- `e9f2243` — `fix: preserve unit scope in dashboard flows`
- `848a97a` — `fix: keep legal case detail rendering read only`
- `5366e1a` — `fix: avoid nested main landmarks in React apps`

`Gemfile.lock` e `docs/superpowers/plans/` já estavam modificados/não rastreados antes deste trabalho e não foram incluídos nos commits.
