# Listagem de Processos Aurora Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar `/legal_cases` como uma listagem React Aurora com cartões padrão, tabela alternável e filtros assíncronos que preservam URLs compartilháveis.

**Architecture:** `LegalCasesController#index` continuará a atender HTML e passará a atender JSON através de `LegalCasesSnapshot`, que aplica `LegalCaseQuery` ao escopo de escritório/unidade já usado na tela. `LegalCasesApp` buscará esse snapshot, atualizará filtros pela query string e renderizará os mesmos casos em cartões ou tabela, com a visualização escolhida mantida em `sessionStorage`.

**Tech Stack:** Rails 8, Minitest, Vite Ruby, React 19, TypeScript, Vitest e Testing Library.

## Global Constraints

- Preserve os filtros atuais: `q`, `phase`, `status`, `priority`, `responsible_name` e `deadline_state`.
- Use apenas o escopo de `current_office` e `scope_by_current_unit`; nenhuma consulta JSON pode vazar processos de outra unidade.
- Cartões são a visão inicial; a preferência `cards`/`table` fica em `sessionStorage` e não altera a URL.
- Atualizações de filtro devem usar JSON e `history.replaceState`, sem recarregar a página.
- Preserve resultados válidos durante atualização e ignore respostas que cheguem fora de ordem.
- Não implementar paginação, ordenação configurável, edição em massa ou mudanças nas regras de negócio.

---

## Estrutura de arquivos

- `app/presenters/legal_cases_snapshot.rb`: serializa filtros, opções e processos da listagem para React, incluindo caminhos e sinais operacionais.
- `app/controllers/legal_cases_controller.rb`: usa o presenter para `GET /legal_cases.json` sem alterar as respostas HTML existentes.
- `test/presenters/legal_cases_snapshot_test.rb`: assegura escopo por unidade, filtros e campos serializados.
- `app/views/legal_cases/index.html.erb`: fornece o ponto de montagem React, mantendo as ações Rails de topbar.
- `app/views/layouts/application.html.erb`: carrega o entrypoint Vite somente no controller `legal_cases`.
- `app/frontend/legal_cases/LegalCasesApp.tsx`: controla carregamento, filtros, URL, recuperação de erro e as duas visualizações.
- `app/frontend/legal_cases/LegalCasesApp.test.tsx`: testa os fluxos assíncronos e de acessibilidade da interface.
- `app/frontend/legal_cases/legalCases.css`: aplica cartões, tabela e estados na linguagem Aurora.
- `app/frontend/entrypoints/legal_cases.tsx`: monta `LegalCasesApp` quando a página contém o root.

### Task 1: Snapshot JSON seguro e filtrável

**Files:**
- Create: `app/presenters/legal_cases_snapshot.rb`
- Modify: `app/controllers/legal_cases_controller.rb:4-13`
- Create: `test/presenters/legal_cases_snapshot_test.rb`
- Modify: `test/controllers/legal_cases_controller_test.rb:24-28`

**Interfaces:**
- Consumes: `LegalCasesSnapshot.new(office:, unit:, all_units_mode:, filters:)`.
- Produces: `as_json` com `{ meta:, filters:, filter_options:, legal_cases:, actions: }`; cada item de `legal_cases` tem `id`, `path`, `internal_number`, `client_name`, `legal_area_name`, `status`, `status_label`, `phase`, `priority`, `responsible_name`, `last_movement`, `next_deadline_on`, `next_deadline_label`, `deadline_tone` e `has_new_imported_events`.

- [x] **Step 1: Write the failing presenter and request tests**

```ruby
test "serializes the filtered cases with operational fields" do
  snapshot = LegalCasesSnapshot.new(office: @office, unit: @unit, all_units_mode: false, filters: { status: "em_analise" })

  entry = snapshot.as_json.fetch(:legal_cases).sole
  assert_equal @case.id, entry.fetch(:id)
  assert_equal legal_case_path(@case), entry.fetch(:path)
  assert_equal "Em análise", entry.fetch(:status_label)
  assert_equal "overdue", entry.fetch(:deadline_tone)
end

test "does not serialize cases outside the selected unit" do
  snapshot = LegalCasesSnapshot.new(office: @office, unit: @unit, all_units_mode: false, filters: {})

  assert_equal [ @case.id ], snapshot.as_json.fetch(:legal_cases).pluck(:id)
end

test "returns the legal cases snapshot as JSON" do
  get legal_cases_url(format: :json), params: { status: "em_analise" }

  assert_response :success
  assert_equal "application/json", response.media_type
  assert_equal [ @legal_case.id ], JSON.parse(response.body).fetch("legal_cases").pluck("id")
end
```

- [x] **Step 2: Run the focused tests to verify they fail**

Run: `bin/rails test test/presenters/legal_cases_snapshot_test.rb test/controllers/legal_cases_controller_test.rb`

Expected: FAIL because `LegalCasesSnapshot` and the JSON payload do not exist.

- [x] **Step 3: Implement the minimal snapshot and JSON branch**

```ruby
# app/controllers/legal_cases_controller.rb
def index
  @filters = legal_case_filters
  if request.format.json?
    render json: LegalCasesSnapshot.new(
      office: current_office,
      unit: current_unit,
      all_units_mode: all_units_mode?,
      filters: @filters
    ).as_json
    return
  end

  # retain the existing HTML assignments below
end
```

```ruby
# app/presenters/legal_cases_snapshot.rb
def legal_cases
  @legal_cases ||= LegalCaseQuery.new(scoped_cases, filters).call.includes(:client).order(updated_at: :desc)
end

def scoped_cases
  scope_by_unit(office.legal_cases)
end
```

Implement `scope_by_unit` with the same unit semantics used by the controller, derive `deadline_tone` from the current date (`overdue`, `today`, `upcoming`, `none`) and use `I18n` labels for status/phase. Include every current filter and its available option list in `filter_options`.

- [x] **Step 4: Run focused tests to verify they pass**

Run: `bin/rails test test/presenters/legal_cases_snapshot_test.rb test/controllers/legal_cases_controller_test.rb`

Expected: PASS with the payload including only permitted, filtered records.

- [x] **Step 5: Commit the snapshot**

```bash
git add app/presenters/legal_cases_snapshot.rb app/controllers/legal_cases_controller.rb test/presenters/legal_cases_snapshot_test.rb test/controllers/legal_cases_controller_test.rb
git commit -m "feat: expose legal cases list snapshot"
```

### Task 2: React list behavior and accessible dual view

**Files:**
- Create: `app/frontend/legal_cases/LegalCasesApp.tsx`
- Create: `app/frontend/legal_cases/LegalCasesApp.test.tsx`
- Create: `app/frontend/entrypoints/legal_cases.tsx`

**Interfaces:**
- Consumes: the Task 1 snapshot from `GET /legal_cases.json?<filters>`.
- Produces: `LegalCasesApp`, rendering `main[aria-label="Processos"]`; it accepts no props and requests `/legal_cases.json` itself.

- [x] **Step 1: Write failing React tests for loading, async filters and view selection**

```tsx
test("loads operational cards and replaces the URL after an async filter", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-001")))
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-002"))))

  render(<LegalCasesApp />)
  expect(screen.getByRole("status")).toHaveTextContent("Carregando processos")
  expect(await screen.findByRole("link", { name: /PROC-001/ })).toBeVisible()

  await userEvent.setup().selectOptions(screen.getByLabelText("Status"), "em_analise")
  expect(await screen.findByRole("link", { name: /PROC-002/ })).toBeVisible()
  expect(window.location.search).toContain("status=em_analise")
})

test("switches from cards to an accessible table and restores that preference", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("PROC-001"))))
  render(<LegalCasesApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Tabela" }))
  expect(screen.getByRole("table", { name: "Listagem de processos" })).toBeVisible()
  expect(sessionStorage.getItem("legal-cases-view")).toBe("table")
})

test("keeps results visible and offers retry when a filter request fails", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-001")))
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-002"))))

  render(<LegalCasesApp />)
  await screen.findByRole("link", { name: /PROC-001/ })
  await userEvent.setup().selectOptions(screen.getByLabelText("Status"), "em_analise")
  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  expect(screen.getByRole("link", { name: /PROC-001/ })).toBeVisible()
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByRole("link", { name: /PROC-002/ })).toBeVisible()
})
```

- [x] **Step 2: Run the React test file to verify it fails**

Run: `npm test -- app/frontend/legal_cases/LegalCasesApp.test.tsx`

Expected: FAIL because the component and entrypoint do not exist.

- [x] **Step 3: Implement minimal behavior around the snapshot contract**

```tsx
type View = "cards" | "table"
const VIEW_KEY = "legal-cases-view"

function fetchSnapshot(filters: URLSearchParams, signal?: AbortSignal) {
  return fetch(`/legal_cases.json?${filters}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}
```

Use an incrementing request id plus `AbortController`: set `isRefreshing` before each request, accept a response only if it belongs to the newest id, then update state. `setFilters` must call `history.replaceState({}, "", `${location.pathname}?${params}`)` before requesting. Render buttons labeled `Cartões` and `Tabela` with `aria-pressed`, defaulting to `cards` and persisting changes in `sessionStorage`. Render all process cards as links and implement the table only from the existing snapshot entries.

- [x] **Step 4: Run React tests to verify they pass**

Run: `npm test -- app/frontend/legal_cases/LegalCasesApp.test.tsx`

Expected: PASS for loading, filtering, URL replacement, retained results, retry and view preference.

- [x] **Step 5: Commit React behavior**

```bash
git add app/frontend/legal_cases/LegalCasesApp.tsx app/frontend/legal_cases/LegalCasesApp.test.tsx app/frontend/entrypoints/legal_cases.tsx
git commit -m "feat: add React legal cases list"
```

### Task 3: Aurora composition, Vite integration and end-to-end checks

**Files:**
- Create: `app/frontend/legal_cases/legalCases.css`
- Modify: `app/frontend/legal_cases/LegalCasesApp.tsx`
- Modify: `app/views/legal_cases/index.html.erb:1-100`
- Modify: `app/views/layouts/application.html.erb:21-25`
- Modify: `test/controllers/legal_cases_controller_test.rb:24-28`

**Interfaces:**
- Consumes: `LegalCasesApp` from Task 2 and `GET /legal_cases.json` from Task 1.
- Produces: an HTML index containing `#react-legal-cases-root`, with Vite assets loaded only for legal cases.

- [x] **Step 1: Write failing integration assertions for the React mount point and Vite entrypoint**

```ruby
test "index mounts the React legal cases application" do
  get legal_cases_url

  assert_response :success
  assert_select "#react-legal-cases-root"
  assert_select "script[src*='legal_cases']"
end
```

Add a React test assertion that a zero-result snapshot exposes `Nenhum processo encontrado para estes filtros.` and a `Limpar filtros` button.

- [x] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/legal_cases_controller_test.rb && npm test -- app/frontend/legal_cases/LegalCasesApp.test.tsx`

Expected: FAIL because the current ERB table has no React root or entrypoint and the empty React state does not exist.

- [x] **Step 3: Add the Aurora layout and integrate it selectively**

```erb
<% content_for :title, "Processos" %>
<% content_for :topbar_actions do %>
  <%= link_to "Fechamento diário", daily_closure_legal_cases_path, class: "btn btn-secondary" %>
  <%= link_to "Novo processo", new_legal_case_path, class: "btn btn-primary" %>
<% end %>
<div id="react-legal-cases-root"></div>
```

```erb
<% if controller_name.in?(["dashboard", "legal_cases"]) %>
  <%= vite_client_tag %>
  <%= vite_react_refresh_tag %>
<% end %>
<%= vite_javascript_tag "dashboard.tsx" if controller_name == "dashboard" %>
<%= vite_javascript_tag "legal_cases.tsx" if controller_name == "legal_cases" %>
```

Import `legalCases.css` from the React app. Style the compact header, advanced filter grid, `Cartões / Tabela` segmented control, cards, deadline/status badges, table, skeleton/loading indicator, error/retry panel and empty state using Aurora variables. Include `:focus-visible`, responsive one-column cards and `prefers-reduced-motion` behavior.

- [x] **Step 4: Run focused tests and build to verify they pass**

Run: `bin/rails test test/presenters/legal_cases_snapshot_test.rb test/controllers/legal_cases_controller_test.rb && npm test -- app/frontend/legal_cases/LegalCasesApp.test.tsx && bin/vite build --clear --mode=development`

Expected: PASS and a Vite manifest containing `entrypoints/legal_cases.tsx`.

- [x] **Step 5: Commit the Aurora integration**

```bash
git add app/frontend/legal_cases/legalCases.css app/frontend/legal_cases/LegalCasesApp.tsx app/views/legal_cases/index.html.erb app/views/layouts/application.html.erb test/controllers/legal_cases_controller_test.rb
git commit -m "feat: apply Aurora design to legal cases"
```

### Task 4: Whole-feature regression verification

**Files:**
- Modify: none

**Interfaces:**
- Consumes: the JSON snapshot and React interface delivered in Tasks 1–3.
- Produces: verification evidence only; no source changes.

- [x] **Step 1: Run the complete Rails suite**

Run: `bin/rails test`

Expected: PASS with no regressions in existing HTML, controller or model behavior.

- [x] **Step 2: Run all frontend tests**

Run: `npm test`

Expected: PASS for dashboard and legal-cases test suites.

- [x] **Step 3: Build final assets**

Run: `bin/vite build --clear --mode=development`

Expected: PASS and manifest entries for both `dashboard.tsx` and `legal_cases.tsx`.

- [x] **Step 4: Inspect the final diff**

Run: `git diff main...HEAD --check && git status --short`

Expected: no whitespace errors and no unintended tracked files; report any pre-existing `Gemfile.lock` modification separately.
