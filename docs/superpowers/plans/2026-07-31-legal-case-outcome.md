# Legal Case Outcome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Registrar o desfecho jurídico como uma ação contextual na tela Show, com confirmação administrativa e ativação segura das cobranças vinculadas.

**Architecture:** O Rails continuará sendo a fonte de autorização e persistência. Um endpoint JSON/HTML dedicado receberá resultado, data e observação; o presenter incluirá o desfecho no snapshot React. O componente Show exibirá um modal administrativo e atualizará o snapshot após confirmação.

**Tech Stack:** Rails 8.1, ActiveRecord, Minitest, React + TypeScript, Vite, CSS Aurora.

## Global Constraints

- Somente administradores podem registrar ou alterar o desfecho.
- Resultado `won` deve ativar cobranças `case_won` aguardando gatilho, sem registrar pagamento.
- A confirmação e a ativação devem ocorrer na mesma transação.
- O formulário geral de edição não deve conter o campo de resultado.
- Suíte Rails pode exigir PostgreSQL configurado; comandos devem reportar bloqueios reais sem mascará-los.

---

### Task 1: Persistência e endpoint seguro de desfecho

**Files:**
- Modify: `app/models/legal_case.rb`
- Modify: `app/controllers/legal_cases_controller.rb`
- Modify: `config/routes.rb`
- Create: `db/migrate/20260731165000_add_outcome_notes_to_legal_cases.rb`
- Modify: `test/controllers/legal_cases_controller_test.rb`
- Modify: `test/models/legal_case_test.rb`

**Interfaces:**
- Endpoint `PATCH /legal_cases/:id/outcome` (`record_outcome_legal_case_path`) recebe `legal_case[outcome]`, `legal_case[outcome_date]` e `legal_case[outcome_notes]`.
- `LegalCase#outcome_confirmed_at` continua armazenando a data/hora da confirmação; `outcome_notes` armazena observação opcional.

- [ ] **Step 1: Escrever testes de autorização e fluxo** para administrador, usuário não administrador, resultado ganho ativando cobrança e resultado inválido.
- [ ] **Step 2: Executar os testes focados** e confirmar falha por rota/ação ausente.
- [ ] **Step 3: Adicionar migration e strong params** para `outcome_notes` e data do desfecho.
- [ ] **Step 4: Implementar `record_outcome`** usando `LegalCase.transaction`, atribuindo usuário/data/notas e chamando `Receivables::OutcomeTrigger` quando o resultado for `won`.
- [ ] **Step 5: Validar data, escritório e resultado** sem permitir alteração por não administrador.
- [ ] **Step 6: Executar sintaxe, RuboCop e testes focados; commitar** com `feat: add legal case outcome endpoint`.

### Task 2: Snapshot e interface React do Show

**Files:**
- Modify: `app/presenters/legal_case_show_snapshot.rb`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Modify: `app/frontend/legal_case_show/legalCaseShow.css`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`
- Modify: `app/views/legal_cases/_form.html.erb`

**Interfaces:**
- Snapshot `case.outcome`, `case.outcome_label`, `case.outcome_confirmed_at`, `case.outcome_confirmed_at_label`, `case.outcome_notes`, `case.outcome_confirmed_by_name` e `permissions.can_record_outcome`.
- O modal envia `PATCH` para `actions.record_outcome` e recarrega o snapshot após sucesso.

- [ ] **Step 1: Escrever testes React** para botão, modal, campos, estado atual e ausência do botão para usuário sem permissão.
- [ ] **Step 2: Executar `npm test -- --run` focado** e confirmar falha pelas propriedades/componentes ausentes.
- [ ] **Step 3: Remover `outcome` do formulário Rails geral**.
- [ ] **Step 4: Adicionar dados de desfecho ao presenter**, incluindo labels e ação autorizada.
- [ ] **Step 5: Implementar botão destacado e modal** no Show, com estados de envio, erro, sucesso e fechamento acessível.
- [ ] **Step 6: Adicionar estilos Aurora responsivos** para botão, selo e modal, respeitando redução de movimento.
- [ ] **Step 7: Executar testes TypeScript, `node --check` quando aplicável e diff check; commitar** com `feat: add outcome action to legal case show`.

### Task 3: Verificação integrada e acabamento

**Files:**
- Modify: `test/controllers/legal_cases_controller_test.rb`
- Modify: `test/presenters/legal_case_show_snapshot_test.rb`
- Modify: `app/views/legal_cases/show.html.erb` only if the modal needs server-provided metadata.

**Interfaces:**
- A tela Show deve continuar carregando sem JavaScript para o fallback HTML, enquanto o React usa o snapshot JSON existente.

- [ ] **Step 1: Adicionar cobertura do snapshot** para desfecho atual, observação e usuário confirmador.
- [ ] **Step 2: Verificar autorização, transação e ativação de cobrança** com testes de integração.
- [ ] **Step 3: Executar `RUBOCOP_CACHE_ROOT=tmp/rubocop bin/rubocop -f simple`, `npm test -- --run` e `git diff --check`.
- [ ] **Step 4: Executar a suíte Rails; registrar bloqueio caso PostgreSQL não esteja disponível.**
- [ ] **Step 5: Revisar textos, acessibilidade, responsividade e estado de resultado já registrado; commitar** com `test: cover legal case outcome flow`.
