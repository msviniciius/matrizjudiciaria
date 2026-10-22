# SDD ledger — plan: docs/superpowers/plans/2026-10-21-integracao-prazos-expedientes-plan.md

## Setup

- Worktree: `.worktrees/legal-deadline-expediente`
- Branch: `feat/legal-deadline-expediente`
- Base commit: `2774b7e`
- Baseline: 289 tests, 1169 assertions, 0 failures, 1 pre-existing error in `InternalCalendarsControllerTest` because the Vite test manifest lacks `entrypoints/internal_calendar.tsx`.
- Test database: temporary local `matrizjuridica_codex_test`, owned by `msvinicius`; worktree-only `config/database.yml` override permits `DATABASE_NAME`.

## Pre-flight plan scan

| Tasks | Shared file/interface | Finding | Ruling |
|---|---|---|---|
| 1 → 2 | `Feriado`, `Suspensao` consumed by `BusinessDaysCalculator` | Calendar entities are created before the calculator and expose the required date fields. | Proceed; use inclusive date ranges and office/jurisdiction scope selected by the calculator. |
| 1 → 6 | `config/application.rb`, calendar models/seeds | Timezone is configured in Task 1; seeds come after models exist. | Proceed; seed dates use `Date.current` under the configured timezone. |
| 2 → 4 | `BusinessDaysCalculator` consumed by `DeadlineCalculator` | Method signatures are explicit and sufficient for business-day addition and remaining-day state calculation. | Proceed; preserve the inclusive semantics in Task 2 tests. |
| 3 → 4 | `Expediente`, `Ciencia`, `Deadline.expediente` | Task 3 creates the domain association; Task 4 adds calculated fields and behavior. | Proceed; Task 3 creates only the pending deadline, Task 4 owns recalculation. |
| 4 → 5 | `DeadlineCalculator`, `Deadline#cumprir!` | Controllers depend on the service and completion interface from Task 4. | Proceed; controllers must call services and enforce office scope. |
| 4 → 6 | deadline states and calculated dates | Job recalculates only deadlines with expediente; manual deadlines remain untouched. | Proceed; job filters by `expediente_id IS NOT NULL`. |
| 4 → 7 | `Deadline.status`, `due_date`, legal state projection | Existing status values are retained while snapshots expose the legal grouping. | Proceed; do not rename existing enum values in this feature. |
| 5 → 7 | routes and snapshot actions | UI depends on controller endpoints and snapshot fields. | Proceed; implement backend actions before React changes. |
| 6 → 7 | job/seed calendar and dashboard queries | Dashboard may read calculated dates after the daily refresh, while manual deadlines remain supported. | Proceed; use `Deadline` as the single source of truth. |
| 7 → 8 | all feature surfaces | Final integration test consumes the completed API and UI snapshot. | Proceed; keep external DJMA/PJe creation outside this plan. |

| Task | Internal consistency | Finding | Ruling |
|---|---|---|---|
| 1 | Yes | Files, validations and timezone setup agree. | No change. |
| 2 | Yes | Calculator signatures match the tests and downstream service. | No change. |
| 3 | Yes | Associations and one-to-one constraints support the pending deadline flow. | No change. |
| 4 | Yes | Legal calculation remains optional for existing manual deadlines. | No change. |
| 5 | Yes | Routes and actions match the selected integration model. | No change. |
| 6 | Yes | Job, recurring schedule and idempotent seeds are aligned. | No change. |
| 7 | Yes | Snapshot/UI changes reuse current deadline surfaces. | No change. |
| 8 | Yes | Final verification covers the end-to-end acceptance criterion. | No change. |

## Rulings

- Ruling: use a separate local test database rather than changing PostgreSQL permissions — the existing database tables are owned by `postgres`, and changing grants or credentials is outside the feature scope.
- Ruling: keep the temporary `DATABASE_NAME` hook in the worktree only and exclude it from feature commits — it exists solely to run tests without mutating existing local databases.
- Ruling: treat the Vite manifest error as pre-existing — it occurs before this branch and is unrelated to the deadline feature; final verification will report it separately unless the feature touches the affected entrypoint.

## Task 1: complete

- Implementer: `c6320df feat: add legal calendar entities`.
- Tests reported: 295 tests, 1202 assertions, 0 failures/errors using the isolated local test database.
- Reviewer: approved spec compliance and code quality; noted that independent test execution with default database credentials was unavailable, while syntax and diff checks passed.

## Task 2: fix round 1

- Reviewer found missing explicit tests for ordinary/zero/consecutive-day `somar_dias_uteis` semantics and unbounded holiday/suspension loading in `app/services/business_days_calculator.rb`.
- Required fix: bound calendar queries to the calculation interval while preserving the public calculator interface, add the missing focused tests, rerun the focused tests and full suite, then request scoped re-review.

## Task 2: complete

- Implementer commits: `6dbd9a2 feat: calculate legal business days`, `7dabb00 fix: bound business day calendar queries`.
- Tests reported: 305 tests, 1220 assertions, 0 failures/errors using the isolated local test database.
- Re-review: both findings approved; no remaining Critical, Important, or Minor issues. Independent reviewer noted default database credentials remain unavailable, while syntax/diff checks passed.

## Task 3: fix round 1

- Reviewer found four integrity issues: deadline/process and expediente/process can diverge; office deadline settings can prefill a pending judicial due date; the expediente deadline relation lacks a unique database index; and `Ciencia` does not validate user office ownership.
- Required fix: enforce matching associations and office scope, prevent pre-science due-date defaults, add unique constraints, add regression tests, rerun focused/full tests, then request scoped re-review.

## Task 3: complete

- Implementer commits: `02ce017 feat: add legal expedients and acknowledgements`, `e8b190d fix: harden legal expedient integrity`.
- Tests reported: 318 tests, 1273 assertions, 0 failures/errors; focused tests and migrations passed.
- Re-review: all four integrity findings approved; no remaining Critical, Important, or Minor issues.

## Task 4: fix round 1

- Reviewer found three important gaps: recalculation without science can reopen completed/suspended deadlines; the extension action can manually overwrite a juridical `due_date`; and update permits cross-office `legal_case_id` reassignment.
- Required fix: preserve terminal/manual states, reject or safely handle juridical extensions, protect target legal case scope, add regression tests, rerun focused/full tests, then request scoped re-review.

## Task 4: complete

- Implementer commits: `7e6deea feat: calculate deadlines from expedients`, `67524ce fix: harden legal deadline updates`.
- Tests reported: 332 tests, 1314 assertions, 0 failures/errors; focused tests and migrations passed.
- Re-review: all three protection findings approved; no remaining Critical, Important, or Minor issues.

## Task 5: fix round 1

- Reviewer found a unit-isolation gap in manual deadline creation: office scope was checked, but a user in active unit A could submit a legal case from unit B in the same office.
- Required fix: enforce active-unit scope in deadline creation and add a regression test; rerun focused tests and request scoped re-review.

## Task 5: complete

- Implementer commits: `782a38e` and `2020a8b`.
- Tests reported: Rails focused 66 passed; frontend focused 33 passed; full frontend has one unrelated pre-existing dashboard failure.
- Re-review: unit-isolation finding approved; no remaining Critical, Important, or Minor issues.

## Task 6: fix round 1

- Reviewer found an important calendar bug: the seed's Easter calculation produced incorrect 2026/2027 dates, shifting movable holidays and forensic suspensions.
- Required fix: replace the computus formula with a validated Gregorian algorithm and add explicit year coverage, then rerun tests and request scoped re-review.

## Task 7: fix round 1

- Reviewer found three UI/query issues: dashboard “Ver todos” links lose each box's date/state scope; manual deadlines are labeled awaiting science in the calendar; completed deadlines without science are labeled awaiting science instead of completed.
- Required fix: preserve box filters in generated links, distinguish manual deadlines from expediente-backed legal deadlines, prioritize completed state, add regression tests, rerun focused tests, then request scoped re-review.

## Task 7: complete

- Implementer commits: `9f2c4c5 feat: show legal deadline states`, `c628e86 fix: address deadline review findings`.
- Tests reported: Rails focused 38/38, 184 assertions; frontend focused 3/3; full frontend retains one unrelated dashboard failure.
- Re-review: all three classification/filter findings approved; no remaining Critical, Important, or Minor issues.

## Task 8: complete

- Commit: `5f873fb test: verify legal deadline workflow`.
- Rails: 361 tests, 1462 assertions, 0 failures; integration test added with 21 assertions.
- Frontend: 80/81, with one pre-existing unrelated dashboard failure.
- Security, migrations, seeds and recurring configuration verified. Brakeman and bundler-audit passed.
- Remaining environment notes: two pre-existing RuboCop offenses and unavailable `bin/importmap` audit.

## Session handoff: 2026-10-22

- Implementation tasks 1–8 are complete and committed on branch `feat/legal-deadline-expediente` in `.worktrees/legal-deadline-expediente`.
- Latest feature commit: `5f873fb test: verify legal deadline workflow`.
- Full Rails verification: 361 tests, 1462 assertions, 0 failures.
- End-to-end integration test: passing, 21 assertions.
- Focused Rails/React tests for the feature: passing.
- Full frontend verification: 80/81; one pre-existing `DashboardApp.test.tsx` failure unrelated to this feature.
- Security checks: Brakeman and bundler-audit passed; two pre-existing RuboCop offenses remain; importmap audit unavailable because `bin/importmap` is absent.
- Uncommitted worktree-only change: `config/database.yml`, adding `DATABASE_NAME` override so tests can use local database `matrizjuridica_codex_test` as user `msvinicius`. Do not commit this change unless intentionally converting it into a project configuration change.
- Main checkout remains separate and retains the user's unrelated local changes. Do not merge, push, or delete the worktree without explicit user direction.
- Final whole-branch code review was dispatched but could not run because the subagent account hit its usage limit. On resume, perform the final review for base `2774b7e` → head `5f873fb`, then address any Critical/Important findings before integration.

## Task 6: complete

- Implementer commits: `6b6d1ad feat: refresh legal deadlines daily`, `aa36520 fix: correct Easter dates in legal calendar seeds`.
- Tests reported: 354 tests, 1400 assertions, 0 failures/errors; job and seed tests passed.
- Re-review: Easter and derived movable holidays approved. Minor note accepted: Easter Sundays themselves are indirectly covered through derived dates rather than asserted directly.

Task 2: complete (commits c6320df..6dbd9a2, tests: env DATABASE_HOST=/var/run/postgresql DATABASE_USERNAME=msvinicius DATABASE_PASSWORD= DATABASE_NAME=matrizjuridica_codex_test bin/rails test test/services/business_days_calculator_test.rb → 6 runs, 13 assertions, 0 failures, 0 errors, 0 skips)

## Task 4: complete

- Implementer commit: `7e6deea feat: calculate deadlines from expedients`.
- Tests reported: focused deadline calculator/model/controller — 19 tests, 53 assertions, 0 failures/errors; full suite — 327 tests, 1294 assertions, 0 failures/errors.
- Report: `.superpowers/sdd/2026-10-21-integracao-prazos-expedientes-plan/task-4-report.md`.
Task 7: complete (commits aa36520..9f2c4c5, tests: env DATABASE_HOST=/var/run/postgresql DATABASE_USERNAME=msvinicius DATABASE_PASSWORD= DATABASE_NAME=matrizjuridica_codex_test bin/rails test test/presenters/deadlines_snapshot_test.rb test/presenters/dashboard_snapshot_test.rb test/controllers/deadlines_controller_test.rb test/controllers/internal_calendars_controller_test.rb → 36 runs, 175 assertions, 0 failures, 0 errors, 0 skips)

Final review: self-review (no subagent tool); no Critical or Important findings remain.

## Resume: 2026-10-22

- Revalidação da branch `2774b7e..5f873fb` concluída no worktree isolado.
- `git diff --check` passou sem erros.
- Rails completo: 361 testes, 1462 assertions, 0 failures, 0 errors, 0 skips.
- Frontend: 80/81 testes; a única falha continua sendo o teste preexistente de edição de responsável no `DashboardApp`.
- Brakeman: sem vulnerabilidades; permanece apenas o aviso de que Rails 8.0.5.1 entra em fim de suporte em 2026-11-07.
- bundler-audit não reportou vulnerabilidades.
- Não foram identificados novos problemas críticos ou importantes na revisão do diff completo.
- Permanece não commitado somente o override temporário de `DATABASE_NAME` em `config/database.yml`.
- Branch continua sem merge/push; decisão de integração permanece pendente de autorização explícita.

## Integração de agendamento gratuito: 2026-10-22

- Adicionado endpoint interno `POST /internal/jobs/refresh-prazos`, protegido pelo mesmo `JOB_TRIGGER_TOKEN` usado pelos jobs agendados existentes.
- Adicionado registro de execução do `RefreshPrazosJob` no controlador interno e teste de sucesso/autorização.
- Adicionado workflow `.github/workflows/refresh-prazos.yml`, executando em dias úteis às 08:00 de Brasília via GitHub Actions, com execução manual disponível.
- Secrets necessários no GitHub: `APP_URL` e `JOB_TRIGGER_TOKEN`.
- Rails completo após a alteração: 362 testes, 1466 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop dos arquivos alterados e validação YAML passaram.
- `config/database.yml` continua sendo apenas o override temporário do banco de testes e ficou fora do commit.

## Diagnóstico do ambiente local: 2026-10-22

- O erro `pg_ext ... undefined symbol: ruby_abi_version` foi identificado como uso do Ruby 3.4.0dev com extensão `pg` incompatível; Ruby 3.4.7 carrega `pg` corretamente.
- O erro seguinte de `fe_sendauth: no password supplied` ocorreu porque o Rails tentava usar `postgres@127.0.0.1`; o ambiente local usa autenticação peer pelo socket com o usuário `msvinicius`.
- O banco de desenvolvimento existente tinha tabelas do proprietário `postgres`, impedindo migrations para `msvinicius`. Ele não foi alterado.
- Criado o banco local separado `matrizjuridica_dev_local`, proprietário `msvinicius`; `db:prepare` e `db:seed` executados com sucesso.
- `config/database.yml` passou a aceitar `DATABASE_NAME` também em `development`; permanece não commitado junto do override de `test`.

## UX/UI de expedientes e prazos: 2026-10-22

- Melhorada a tela do processo para tornar o fluxo do expediente mais claro.
- O formulário agora expõe tipo, origem, contagem, data de disponibilização e quantidade de dias, com ajuda contextual e CTA explícito.
- O prazo jurídico agora mostra status em badge, metadados separados, origem do expediente e descrição da intimação.
- A ciência agora possui data visível e editável; o protocolo de cumprimento também ganhou rótulo explícito.
- Teste frontend da tela do processo: 28/28 passando.
- Suíte frontend completa: 81/82; permanece uma falha preexistente no teste de responsável do dashboard.

## Alinhamento ao padrão visual do projeto: 2026-10-22

- Refatorado o formulário de novo expediente para reutilizar `app-form`, `aurora-form`, `form-section`, `form-grid`, `form-hint`, `field-help`, `form-actions` e botões globais `btn-primary/secondary`.
- Removida a duplicação de estilos de campos e botões no CSS da tela; mantidos apenas layout e estados específicos do card de prazo/expediente.
- Ações de registrar ciência e cumprir prazo agora seguem o padrão de botões e espaçamento dos demais formulários.
- Teste focado da tela: 28/28 passando.
- Suíte frontend: 81/82; permanece a falha preexistente em `dashboard/DashboardApp.test.tsx` sobre edição de responsável.
- `git diff --check`: aprovado.

## Segunda revisão visual: 2026-10-22

- A captura revelou que a primeira padronização ainda deixava três contêineres aninhados e o campo de descrição sem layout de formulário adequado.
- Removido o painel interno redundante; o expediente agora usa a própria área expandida da lateral como contêiner visual.
- Corrigido o layout dos rótulos/campos, incluindo descrição em largura total e grade consistente para os demais campos.
- Teste focado após a revisão: 28/28 passando.
- O servidor local já estava ativo na porta 3002; a nova inicialização foi impedida pelo PID existente, sem alteração de dados.

## Terceira revisão visual: 2026-10-22

- Rebaixado o agrupamento de ações da lateral para não parecer um card dentro de outro card.
- O expediente agora é o único painel visual da seção, enquanto as ações administrativas ficam soltas e alinhadas abaixo.
- Reforçada a hierarquia do título do expediente e mantido o contraste do formulário no tema Aurora.

## Refação de interação do expediente: 2026-10-22

- Removido o formulário complexo da coluna lateral; a lateral agora exibe apenas uma ação primária compacta.
- Criado modal próprio de cadastro de expediente, seguindo o padrão já usado para desfecho e financeiro.
- O modal tem fechamento por botão, clique fora e tecla Escape, além de largura adequada para a grade de campos.
- Teste atualizado para abrir o modal e validar os campos do fluxo: 28/28 passando.

## Validação visual real e correção do modal: 2026-10-22

- Screenshot real do ambiente local revelou que o modal estava dentro de `content-surface`, cujo `backdrop-filter` criava um containing block para elementos `position: fixed`.
- O modal foi movido para um portal em `document.body`, eliminando o deslocamento vertical e o corte na viewport.
- Screenshot após a correção: modal centralizado, com largura de 736px, altura de 719px e todos os campos/ações visíveis.

## Ajuste de contexto da ação: 2026-10-22

- O CTA “Novo expediente” foi removido da lateral administrativa e passou para o cabeçalho da seção “Prazos”.
- A ação agora aparece exatamente no contexto em que o prazo será criado, reduzindo ruído na lateral.
- Screenshot real validou o resultado: cabeçalho “Prazos” com CTA compacto e card de prazo separado das ações administrativas.

## Simplificação visual do card de prazo: 2026-10-22

- Removidos fundos e bordas dos metadados internos, mantendo apenas divisores leves.
- A origem do expediente passou a ser uma faixa contextual simples, sem um segundo card.
- Ações do prazo passaram para um rodapé alinhado, com campo e botão na mesma linha em telas largas.
- Screenshot real validou a redução de camadas visuais.
- Teste focado: 28/28 passando.

## Consistência do CTA com o padrão global: 2026-10-22

- O botão “Novo expediente” passou a usar as classes globais `btn btn-primary`, alinhando cor, altura, tipografia e estados às demais ações do sistema.
- Screenshot real após a alteração validou a consistência visual do CTA no cabeçalho de “Prazos”.
- Teste focado permanece em 28/28 passando.

## Revisão de feedback visual: 2026-10-22

- Revalidação confirmou que a captura anexada continua representando a versão antiga da tela, enquanto a renderização atual já usa modal e CTA contextual em “Prazos”.
- O CTA foi alinhado explicitamente ao botão primário global do projeto.
- Screenshot atual do card de Prazos foi gerado para comparação visual.

## Ajuste de clareza do fluxo: 2026-10-22

- O estado do prazo agora prioriza o fluxo operacional: expediente sem ciência exibe “Aguardando ciência” e a única ação disponível é “Registrar ciência”.
- “Cumprir prazo” só aparece depois que a ciência foi registrada, evitando uma ação prematura.
- “Origem do prazo” foi renomeado para “Expediente vinculado”, alinhando o texto ao domínio da feature.
- O bloco “Próxima ação” foi incluído em cada prazo não concluído.
- O indicador de expansão das seções deixou de usar “+” e passou a usar chevrons, evitando conflito visual com “Novo expediente”.
- Teste focado: 28/28 passando; `git diff --check` aprovado.
- Suíte frontend completa: 81/82; permanece a falha preexistente em `dashboard/DashboardApp.test.tsx` sobre o campo “Responsável do processo SEI01”, sem relação com esta alteração.

## Correção do acordeão de Prazos: 2026-10-22

- Identificado que o atributo HTML `hidden` era aplicado pelo React, mas a regra `.react-legal-case-show__operational-content { display: grid; }` continuava exibindo o conteúdo no navegador.
- Adicionada a regra explícita `.react-legal-case-show__operational-content[hidden] { display: none; }`.
- Adicionado teste de regressão para minimizar e maximizar “Prazos” sem abrir o modal de novo expediente.
- Teste focado: 29/29 passando; `git diff --check` aprovado.

## Correção da listagem global de Prazos: 2026-10-22

- A captura analisada era da tela global `/deadlines`, não da seção de prazos do processo.
- Corrigido o fluxo para não exibir “Cumprir prazo” enquanto o expediente aguarda ciência; a listagem agora apresenta apenas “Dar ciência” nesse estado.
- Corrigido o layout dos controles: protocolo estilizado, input e botão alinhados na mesma linha em telas largas e empilhados em telas menores.
- “Cumprir” foi renomeado para “Cumprir prazo” para manter consistência com a tela do processo.
- Testes focados de prazos e processo: 36/36 passando; `git diff --check` aprovado.

## Remoção da criação direta na listagem global: 2026-10-22

- Removido o botão “Novo prazo” do cabeçalho da listagem global de prazos.
- A criação passa a ficar contextualizada no processo, através de “Novo expediente”, evitando dois caminhos concorrentes para o mesmo fluxo.
- Adicionado teste garantindo que a listagem não exiba mais o link de criação direta.
- Testes focados de prazos e processo: 36/36 passando.
