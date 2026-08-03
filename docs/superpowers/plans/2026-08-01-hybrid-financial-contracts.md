# Hybrid Financial Contracts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evoluir o financeiro para contratos únicos por processo, com honorários fixos, percentual opcional, parcelas de 1 a 12 vezes, recebimento integral e comprovante.

**Architecture:** Criar entidades separadas para contrato, cobrança e recebimento, mantendo o legado de `Receivable` durante a migração. O Show do processo será a interface principal; serviços isolados calcularão honorários e distribuirão parcelas. Active Storage anexará um contrato ao contrato financeiro e um comprovante a cada recebimento.

**Tech Stack:** Rails 8.1, ActiveRecord/PostgreSQL, Active Storage, Minitest, React + TypeScript, Vite, CSS Aurora.

## Global Constraints

- Cada processo poderá ter exatamente um contrato financeiro.
- O padrão será honorário fixo; `includes_percentage` habilita percentual adicional.
- A base do percentual será `claim_value` ou `client_received`, informado manualmente.
- O parcelamento terá de 1 a 12 cobranças; a distribuição inicial será igualitária e a última parcela absorverá centavos.
- Cada parcela terá no máximo um recebimento integral e um comprovante.
- Tipos de pagamento: Pix, dinheiro, cartão de crédito e cartão de débito.
- Todos os perfis poderão editar contratos e anexar documentos nesta primeira versão.
- Não implementar pagamentos parciais, descontos, estornos ou cancelamentos nesta etapa.
- Preservar contas legadas durante a migração e não incluir alterações locais preexistentes em `db/schema.rb` sem revisão.

---

### Task 1: Modelos, migrations e compatibilidade legada

**Files:**
- Create: `app/models/financial_contract.rb`
- Create: `app/models/financial_installment.rb`
- Create: `app/models/financial_payment.rb`
- Modify: `app/models/legal_case.rb`
- Create: `db/migrate/20260801170000_create_financial_contracts.rb`
- Create: `db/migrate/20260801170100_create_financial_installments.rb`
- Create: `db/migrate/20260801170200_create_financial_payments.rb`
- Modify: `test/models/legal_case_test.rb`
- Create: `test/models/financial_contract_test.rb`
- Create: `test/models/financial_installment_test.rb`
- Create: `test/models/financial_payment_test.rb`

**Interfaces:**
- `LegalCase#financial_contract` is one-to-one.
- `FinancialContract` exposes enums `percentage_basis: claim_value/client_received`, validates one process, fixed amount, optional percentage and 1..12 installments.
- `FinancialInstallment#register_payment!` accepts `amount:, paid_at:, payment_method:, recorded_by:, proof:` and only accepts the exact installment amount once.

- [ ] Write failing model tests for uniqueness, office/process consistency, percentage flag, installment limit and one-payment rule.
- [ ] Add tables, unique index on `financial_contracts.legal_case_id`, foreign keys and Active Storage attachments (`contract_document` and `proof`).
- [ ] Implement associations, enums and validations with decimal precision 12/2.
- [ ] Add a compatibility path for existing process-linked `receivables` so they remain visible while new contracts are introduced.
- [ ] Run focused model tests, syntax, RuboCop and diff check; commit `feat: add hybrid financial contract models`.

### Task 2: Calculation and installment generation services

**Files:**
- Create: `app/services/financial_contracts/calculator.rb`
- Create: `app/services/financial_contracts/installment_builder.rb`
- Create: `test/services/financial_contracts/calculator_test.rb`
- Create: `test/services/financial_contracts/installment_builder_test.rb`

**Interfaces:**
- `FinancialContracts::Calculator.call(fixed_amount:, includes_percentage:, percentage:, percentage_basis:, claim_value:, client_received:)` returns a decimal total.
- `FinancialContracts::InstallmentBuilder.call(contract:, count:, first_due_date:)` creates 1..12 installments whose sum equals the total and puts rounding difference in the final installment.

- [ ] Add failing tests for fixed-only, fixed-plus-claim-value percentage and fixed-plus-client-received percentage.
- [ ] Add tests requiring `client_received` when that basis is selected and rejecting invalid percentages/counts.
- [ ] Add tests for equal distribution and cent rounding, including 1 and 12 installments.
- [ ] Implement calculator with decimal-safe arithmetic and builder in a transaction.
- [ ] Run focused tests and commit `feat: calculate and split financial contracts`.

### Task 3: Show financial panel and contract workflow

**Files:**
- Modify: `app/presenters/legal_case_show_snapshot.rb`
- Modify: `app/controllers/legal_cases_controller.rb`
- Create: `app/controllers/financial_contracts_controller.rb`
- Modify: `config/routes.rb`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Modify: `app/frontend/legal_case_show/legalCaseShow.css`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`

**Interfaces:**
- Snapshot exposes `financial_contract`, `installments`, and actions for configure/edit, client-received value and receipt registration.
- Contract endpoint accepts fixed amount, percentage flag/basis/value, installment count and first due date.
- All profiles can access the process-scoped financial actions; every record is scoped to the current office.

- [ ] Add request and React tests for empty panel, fixed contract and fixed-plus-percentage contract.
- [ ] Add form/modal sections for contract setup, percentage basis, value received and installment preview.
- [ ] Implement office/process-scoped create/update actions using calculator and builder services.
- [ ] Render contract totals, base, attached contract document and installment status in the Show.
- [ ] Run focused React/Rails tests and commit `feat: add financial contract workflow to case show`.

### Task 4: Receipts, payment types and documents

**Files:**
- Modify: `app/controllers/financial_installments_controller.rb`
- Create: `app/views/financial_installments/_payment_form.html.erb`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Modify: `app/frontend/legal_case_show/legalCaseShow.css`
- Modify: `test/controllers/financial_installments_controller_test.rb`
- Modify: `app/models/financial_payment.rb`

**Interfaces:**
- `POST /financial_installments/:id/payment` receives full amount, datetime, payment type and one proof attachment.
- Payment types are `pix`, `cash`, `credit_card`, `debit_card` with Portuguese labels.

- [ ] Add failing tests for exact amount, one-payment uniqueness, payment type validation, proof attachment and office authorization.
- [ ] Implement payment registration transaction with recorded user/time and Active Storage proof.
- [ ] Add Show action **Registrar recebimento** only for unpaid installments and display proof link after payment.
- [ ] Reject partial, second or cross-office payments with clear errors.
- [ ] Run focused tests and commit `feat: register installment payments and proofs`.

### Task 5: Legacy dashboard, navigation and final verification

**Files:**
- Modify: `app/services/receivables/query.rb`
- Modify: `app/services/receivables/summary.rb`
- Modify: `app/views/receivables/index.html.erb`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `config/locales/pt-BR.yml`
- Create: `test/system/financial_contracts_test.rb` if system tests are enabled

**Interfaces:**
- Existing admin dashboard continues showing legacy and new process-linked financial data without double-counting migrated records.

- [ ] Add coverage for dashboard totals with fixed, percentage and paid installment data under filters.
- [ ] Add navigation labels and Portuguese payment/contract status translations.
- [ ] Verify legacy receivables remain accessible and new installment data appears in the appropriate process context.
- [ ] Run `npm test`, targeted Rails tests, RuboCop and `git diff --check`; document PostgreSQL blocks honestly.
- [ ] Commit `feat: integrate hybrid financial contracts`.
