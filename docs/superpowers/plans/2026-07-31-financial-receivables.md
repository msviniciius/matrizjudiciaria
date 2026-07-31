# Módulo de Contas a Receber Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um módulo administrativo de contas a receber, vinculado opcionalmente a processos/clientes, com pagamentos parciais, gatilho por processo ganho e visão consolidada por escritório/unidade.

**Architecture:** Rails MVC com um agregado `Receivable` pertencente ao escritório e referências opcionais a cliente, processo e unidade. O resultado jurídico será um atributo explícito de `LegalCase`; um serviço de domínio ativará contas cujo gatilho seja “processo ganho”. A interface seguirá os padrões Aurora existentes, com dashboard geral por padrão e filtros por unidade.

**Tech Stack:** Rails 8.1, PostgreSQL, Active Record migrations, ERB, Rails controllers, JavaScript existente em `app/assets/javascripts/app.js`, CSS global em `app/assets/stylesheets/application.css`, Minitest e Vitest quando houver componentes React.

## Global Constraints

- Apenas usuários administradores poderão acessar o módulo financeiro.
- Toda conta pertence a um escritório (`office_id`) e nunca pode atravessar escritórios.
- A visão padrão consolida matriz e unidades; o período padrão é os últimos 30 dias.
- Processo e cliente são vínculos opcionais; quando houver processo, cliente e unidade devem ser derivados dele.
- Processo “ganho” torna a cobrança exigível, mas nunca registra pagamento automaticamente.
- Pagamento parcial deve atualizar saldo e status sem criar parcelas nesta primeira versão.
- O resultado jurídico é separado do status operacional do processo e confirmado manualmente.

---

### Task 1: Modelar resultado jurídico do processo

**Files:**
- Create: `db/migrate/20260731160000_add_outcome_to_legal_cases.rb`
- Modify: `app/models/legal_case.rb`
- Modify: `app/models/user.rb`
- Test: `test/models/legal_case_test.rb`

**Interfaces:**
- Produces `LegalCase#outcome`, `LegalCase#outcome_confirmed_at` e `LegalCase#outcome_confirmed_by`.
- `LegalCase::OUTCOMES` deve conter `undefined`, `won`, `lost`, `settled` e `partially_won`.

- [ ] **Step 1: Write the failing model tests** para aceitar apenas os cinco resultados e registrar usuário/data quando o resultado for confirmado.
- [ ] **Step 2: Run test to verify it fails**

```bash
bin/rails test test/models/legal_case_test.rb
```

Expected: FAIL porque as colunas e o enum de resultado ainda não existem.

- [ ] **Step 3: Add the migration and model API**

```ruby
add_column :legal_cases, :outcome, :string, null: false, default: "undefined"
add_column :legal_cases, :outcome_confirmed_at, :datetime
add_reference :legal_cases, :outcome_confirmed_by, foreign_key: { to_table: :users }
add_index :legal_cases, :outcome
```

Use `enum :outcome, { undefined: "undefined", won: "won", lost: "lost", settled: "settled", partially_won: "partially_won" }, prefix: true` and validate inclusion.

- [ ] **Step 4: Run the focused tests**

```bash
bin/rails test test/models/legal_case_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add db/migrate/20260731160000_add_outcome_to_legal_cases.rb app/models/legal_case.rb app/models/user.rb test/models/legal_case_test.rb
git commit -m "feat: add explicit legal case outcomes"
```

---

### Task 2: Criar o agregado de contas a receber

**Files:**
- Create: `db/migrate/20260731161000_create_receivables.rb`
- Create: `app/models/receivable.rb`
- Modify: `app/models/office.rb`
- Modify: `app/models/client.rb`
- Modify: `app/models/legal_case.rb`
- Modify: `app/models/unit.rb`
- Test: `test/models/receivable_test.rb`

**Interfaces:**
- Produces `Receivable#balance`, `Receivable#overdue?`, `Receivable#activate!`, `Receivable#register_payment!` and scopes `for_period`, `by_status`, `by_unit`.
- Statuses: `awaiting_trigger`, `pending`, `partial`, `received`, `overdue`, `canceled`.
- Triggers: `manual`, `case_started`, `case_won`.

- [ ] **Step 1: Write failing model tests** cobrindo vínculo ao escritório, processo/cliente opcionais, unidade do mesmo escritório, saldo, pagamento parcial, quitação e vencimento.
- [ ] **Step 2: Run focused tests**

```bash
bin/rails test test/models/receivable_test.rb
```

Expected: FAIL because `Receivable` não existe.

- [ ] **Step 3: Create the migration** com `office_id` obrigatório; `unit_id`, `client_id` e `legal_case_id` opcionais; `description`; `amount` e `amount_paid` como decimal `precision: 12, scale: 2`; `due_date`; `paid_at`; `payment_method`; `notes`; `trigger`; `triggered_at`; `status`; timestamps e índices por escritório, unidade, processo, cliente, status e vencimento.
- [ ] **Step 4: Implement model invariants**

```ruby
def balance
  amount - amount_paid
end

def register_payment!(value:, paid_at: Date.current, payment_method: nil)
  self.amount_paid = amount_paid + value
  self.paid_at = paid_at if amount_paid >= amount
  self.status = amount_paid.zero? ? "pending" : (amount_paid >= amount ? "received" : "partial")
  self.payment_method = payment_method if payment_method.present?
  save!
end
```

Validate positive `amount`, non-negative `amount_paid`, `amount_paid <= amount`, and same-office relationships. Derive `overdue` only for open accounts whose due date is before today.

- [ ] **Step 5: Run focused tests and commit**

```bash
bin/rails test test/models/receivable_test.rb
git add db/migrate/20260731161000_create_receivables.rb app/models/receivable.rb app/models/office.rb app/models/client.rb app/models/legal_case.rb app/models/unit.rb test/models/receivable_test.rb
git commit -m "feat: add receivable domain model"
```

---

### Task 3: Ativar cobranças pelo resultado “ganho”

**Files:**
- Create: `app/services/receivables/outcome_trigger.rb`
- Modify: `app/controllers/legal_cases_controller.rb`
- Modify: `app/models/receivable.rb`
- Test: `test/services/receivables/outcome_trigger_test.rb`
- Test: `test/controllers/legal_cases_controller_test.rb`

**Interfaces:**
- `Receivables::OutcomeTrigger.call(legal_case:, confirmed_by:)` ativa somente contas do processo com `trigger: "case_won"` e `status: "awaiting_trigger"`.

- [ ] **Step 1: Write failing service tests** garantindo que somente o resultado `won` ative contas, que outras contas não sejam alteradas e que o usuário/data de confirmação sejam gravados.
- [ ] **Step 2: Run focused tests**

```bash
bin/rails test test/services/receivables/outcome_trigger_test.rb
```

Expected: FAIL porque o serviço ainda não existe.

- [ ] **Step 3: Implement service and controller integration** em uma transação. A atualização do resultado deve aceitar `outcome` apenas para administrador e chamar o serviço quando houver transição para `won`; ativação muda para `pending` e preenche `triggered_at`, sem alterar `amount_paid`.
- [ ] **Step 4: Run service/controller tests**

```bash
bin/rails test test/services/receivables/outcome_trigger_test.rb test/controllers/legal_cases_controller_test.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/services/receivables/outcome_trigger.rb app/controllers/legal_cases_controller.rb app/models/receivable.rb test/services/receivables/outcome_trigger_test.rb test/controllers/legal_cases_controller_test.rb
git commit -m "feat: activate receivables when a case is won"
```

---

### Task 4: Implementar autorização e consultas administrativas

**Files:**
- Create: `app/controllers/receivables_controller.rb`
- Create: `app/services/receivables/query.rb`
- Modify: `config/routes.rb`
- Test: `test/controllers/receivables_controller_test.rb`
- Test: `test/services/receivables/query_test.rb`

**Interfaces:**
- Routes: `resources :receivables, except: [:show]` plus member actions `register_payment` and `cancel`.
- `Receivables::Query.new(office:, params:).call` returns a relation limited to the office and filtered by `period`, `unit_id`, `client_id`, `legal_case_id` and `status`.

- [ ] **Step 1: Write failing controller/query tests** para negar não administradores, impedir acesso cruzado entre escritórios, usar últimos 30 dias como padrão e manter visão geral quando `unit_id` estiver ausente.
- [ ] **Step 2: Run focused tests**

```bash
bin/rails test test/controllers/receivables_controller_test.rb test/services/receivables/query_test.rb
```

- [ ] **Step 3: Implement `ReceivablesController`** com `before_action :require_admin!`, contexto de `current_office`, strong parameters e ações de criação/edição/atualização/cancelamento/recebimento parcial.
- [ ] **Step 4: Implement the query service** com período inclusivo dos últimos 30 dias quando não informado e filtro de unidade validado por `current_office.units`.
- [ ] **Step 5: Run tests and commit**

```bash
bin/rails test test/controllers/receivables_controller_test.rb test/services/receivables/query_test.rb
git add app/controllers/receivables_controller.rb app/services/receivables/query.rb config/routes.rb test/controllers/receivables_controller_test.rb test/services/receivables/query_test.rb
git commit -m "feat: add receivables administration"
```

---

### Task 5: Construir o dashboard de contas a receber

**Files:**
- Create: `app/services/receivables/summary.rb`
- Create: `app/views/receivables/index.html.erb`
- Create: `app/views/receivables/_filters.html.erb`
- Create: `app/views/receivables/_table.html.erb`
- Create: `app/views/receivables/new.html.erb`
- Create: `app/views/receivables/edit.html.erb`
- Create: `app/views/receivables/_form.html.erb`
- Modify: `app/controllers/receivables_controller.rb`
- Modify: `app/assets/stylesheets/application.css`
- Test: `test/services/receivables/summary_test.rb`

**Interfaces:**
- `Receivables::Summary.new(scope:, reference_date:).call` returns keys `expected`, `received`, `open_balance`, `overdue`, `partial`, `upcoming` and `received_by_day`.

- [ ] **Step 1: Write failing summary tests** para totais, contas vencidas, parciais, próximos vencimentos e agrupamento diário.
- [ ] **Step 2: Run focused summary tests**

```bash
bin/rails test test/services/receivables/summary_test.rb
```

- [ ] **Step 3: Implement summary service** sem consultas fora do escopo já filtrado pelo escritório/unidade.
- [ ] **Step 4: Build the Aurora views** com cards de indicadores, gráfico simples de recebimentos, filtros padrão de 30 dias, tabela de contas e ações de receber/editar/cancelar.
- [ ] **Step 5: Run tests and commit**

```bash
bin/rails test test/services/receivables/summary_test.rb test/controllers/receivables_controller_test.rb
git add app/services/receivables/summary.rb app/views/receivables app/controllers/receivables_controller.rb app/assets/stylesheets/application.css test/services/receivables/summary_test.rb
git commit -m "feat: add receivables dashboard"
```

---

### Task 6: Integrar seleção de processo/cliente e contexto de unidade

**Files:**
- Modify: `app/views/receivables/_form.html.erb`
- Modify: `app/controllers/receivables_controller.rb`
- Modify: `app/assets/javascripts/app.js`
- Test: `test/controllers/receivables_controller_test.rb`

**Interfaces:**
- O formulário deve aceitar processo ou cliente e expor `data-receivable-process-select` para preencher cliente/unidade do processo.

- [ ] **Step 1: Add failing request tests** para herdar cliente/unidade do processo, rejeitar associações de outro escritório e permitir conta sem processo.
- [ ] **Step 2: Implement process lookup** usando endpoints JSON existentes ou um endpoint administrativo restrito, sem permitir que o navegador escolha cliente/unidade incompatíveis.
- [ ] **Step 3: Implement form sections** “Vínculo”, “Cobrança” e “Recebimento”, mantendo moeda e datas no padrão atual.
- [ ] **Step 4: Run focused tests and commit**

```bash
bin/rails test test/controllers/receivables_controller_test.rb
git add app/views/receivables/_form.html.erb app/controllers/receivables_controller.rb app/assets/javascripts/app.js test/controllers/receivables_controller_test.rb
git commit -m "feat: link receivables to cases and clients"
```

---

### Task 7: Adicionar navegação, integração visual e cobertura final

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Modify: `config/locales/pt-BR.yml`
- Test: `test/controllers/receivables_controller_test.rb`
- Test: `test/system/receivables_test.rb` (create if system tests are enabled)

- [ ] **Step 1: Add the administrator-only navigation item** “Contas a receber” under the administrative/configuration area.
- [ ] **Step 2: Add Portuguese labels and status translations** for all statuses, triggers and outcome values.
- [ ] **Step 3: Add request/system coverage** para navegação, autorização, filtros geral/unidade, criação, pagamento parcial e gatilho de processo ganho.
- [ ] **Step 4: Run the complete verification suite**

```bash
RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop -f simple
bin/rails test
npm test -- --run
git diff --check
```

- [ ] **Step 5: Commit**

```bash
git add app/views/layouts/application.html.erb config/locales/pt-BR.yml test/controllers/receivables_controller_test.rb test/system/receivables_test.rb
git commit -m "feat: finish receivables module integration"
```
