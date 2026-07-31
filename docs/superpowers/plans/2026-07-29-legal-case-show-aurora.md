# Detalhe de Processo Aurora Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar `/legal_cases/:id` em uma central de comando React de leitura, com timeline, alertas e seções operacionais recolhíveis.

**Architecture:** `LegalCasesController#show` responderá HTML e JSON por meio de `LegalCaseShowSnapshot`, sempre partindo do processo já limitado à unidade. `LegalCaseShowApp` buscará o snapshot e renderizará o cabeçalho Aurora, timeline progressiva, painel contextual e acordeões, encaminhando ações para os fluxos Rails existentes.

**Tech Stack:** Rails 8, Minitest, Vite Ruby, React 19, TypeScript, Vitest e Testing Library.

## Global Constraints

- O snapshot e todas as rotas do detalhe preservam o escopo de escritório/unidade; sem unidade e fora de todas as unidades, não retornar dados.
- A central é somente leitura: não criar edição inline, criação interna nem atualização assíncrona local.
- Ações devem usar os caminhos Rails existentes para editar, andamento, prazo, tarefa, perícia, PDF, calendário e sincronização.
- Timeline é o foco principal; prazos, tarefas e perícias são acordeões abertos automaticamente apenas quando houver alerta.
- Sem polling, paginação, alteração de regras de negócio ou mudança nas telas de formulário.

---

### Task 1: Snapshot seguro do detalhe

**Files:**
- Create: `app/presenters/legal_case_show_snapshot.rb`
- Modify: `app/controllers/legal_cases_controller.rb`
- Create: `test/presenters/legal_case_show_snapshot_test.rb`
- Modify: `test/controllers/legal_cases_controller_test.rb`

**Interfaces:**
- Consumes: `LegalCaseShowSnapshot.new(legal_case:)`.
- Produces: JSON com `case`, `alerts`, `next_action`, `timeline`, `deadlines`, `tasks`, `exams` e `actions`.

- [x] **Step 1: Write failing snapshot tests**

```ruby
test "serializes the command-center detail only for the scoped case" do
  snapshot = LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json

  assert_equal @legal_case.id, snapshot.fetch(:case).fetch(:id)
  assert_equal edit_legal_case_path(@legal_case), snapshot.fetch(:actions).fetch(:edit)
  assert_equal @legal_case.internal_number, snapshot.fetch(:case).fetch(:internal_number)
end

test "show JSON does not expose a case outside the current unit" do
  get legal_case_url(@other_unit_case, format: :json)

  assert_response :not_found
end
```

- [x] **Step 2: Verify RED**

Run: `bin/rails test test/presenters/legal_case_show_snapshot_test.rb test/controllers/legal_cases_controller_test.rb`

Expected: FAIL because the presenter and show JSON response do not exist.

- [x] **Step 3: Implement the minimal snapshot and controller branch**

```ruby
def show
  if request.format.json?
    render json: LegalCaseShowSnapshot.new(legal_case: @legal_case).as_json
    return
  end

  load_case_related_collections
  @legal_case.touch(:last_viewed_events_at) if @legal_case.has_new_imported_events?
end
```

Serialize labels with I18n, derive alert booleans from existing model predicates, include only routes already available in the HTML view, and order timeline/deadlines/tasks/exams exactly as `load_case_related_collections` does.

- [x] **Step 4: Verify GREEN**

Run: `bin/rails test test/presenters/legal_case_show_snapshot_test.rb test/controllers/legal_cases_controller_test.rb`

Expected: PASS with an authorized snapshot and not-found response across units.

- [x] **Step 5: Commit**

```bash
git add app/presenters/legal_case_show_snapshot.rb app/controllers/legal_cases_controller.rb test/presenters/legal_case_show_snapshot_test.rb test/controllers/legal_cases_controller_test.rb
git commit -m "feat: expose legal case detail snapshot"
```

### Task 2: React central de comando

**Files:**
- Create: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Create: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`
- Create: `app/frontend/entrypoints/legal_case_show.tsx`

**Interfaces:**
- Consumes: `GET /legal_cases/:id.json` from Task 1.
- Produces: `LegalCaseShowApp`, mounted in `#react-legal-case-show-root`.

- [ ] **Step 1: Write failing React tests**

```tsx
test("renders the command center and opens an alerted deadline section", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Central de comando" })).toBeVisible()
  expect(screen.getByRole("button", { name: /Prazos/ })).toHaveAttribute("aria-expanded", "true")
  expect(screen.getByRole("link", { name: "Editar processo" })).toHaveAttribute("href", "/legal_cases/1/edit")
})

test("reveals older timeline items on demand and keeps actions as links", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWithSixTimelineItems)))
  render(<LegalCaseShowApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: /Mostrar mais/ }))
  expect(screen.getByText("Andamento antigo")).toBeVisible()
})

test("shows an error and retry action when the snapshot fails", async () => {
  vi.stubGlobal("fetch", vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce(okResponse(snapshot)))
  render(<LegalCaseShowApp />)
  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível carregar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByRole("heading", { name: "Central de comando" })).toBeVisible()
})
```

- [ ] **Step 2: Verify RED**

Run: `npm test -- app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`

Expected: FAIL because the component does not exist.

- [ ] **Step 3: Implement minimal read-only command center**

Use `fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } })`, loading/error/retry states, and data-only navigation links. Implement an `OperationalSection` component with `button`, `aria-expanded` and default state from each section’s `has_alert`; render the first five timeline items, then reveal the remainder using a button.

- [ ] **Step 4: Verify GREEN**

Run: `npm test -- app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`

Expected: PASS for command center, alerted sections, timeline expansion and failure recovery.

- [ ] **Step 5: Commit**

```bash
git add app/frontend/legal_case_show/LegalCaseShowApp.tsx app/frontend/legal_case_show/LegalCaseShowApp.test.tsx app/frontend/entrypoints/legal_case_show.tsx
git commit -m "feat: add React legal case command center"
```

### Task 3: Aurora composition and selective Vite loading

**Files:**
- Create: `app/frontend/legal_case_show/legalCaseShow.css`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Modify: `app/views/legal_cases/show.html.erb`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `test/controllers/legal_cases_controller_test.rb`

**Interfaces:**
- Consumes: Task 1 snapshot and Task 2 app.
- Produces: `#react-legal-case-show-root` with Vite asset `legal_case_show.tsx` only on `legal_cases#show`.

- [ ] **Step 1: Write failing integration and empty-state tests**

```ruby
test "show mounts the React command center" do
  get legal_case_url(@legal_case)

  assert_response :success
  assert_select "#react-legal-case-show-root"
  assert_select "script[src*='legal_case_show']"
end
```

Add a React assertion for an empty timeline and verify each accordion has a visible heading and toggle button.

- [ ] **Step 2: Verify RED**

Run: `bin/rails test test/controllers/legal_cases_controller_test.rb && npm test -- app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`

Expected: FAIL because the server-rendered detail has no React root or entrypoint.

- [ ] **Step 3: Add Aurora CSS and mount integration**

Replace the show body with the root while retaining title/topbar actions. Load Vite client/refresh for dashboard and legal_cases, then choose `legal_case_show.tsx` only when `controller_name == "legal_cases" && action_name == "show"`. Style the two-column command center, health/alert badges, timeline, contextual rail, collapsible sections, responsive mobile layout, focus styles and reduced motion.

- [ ] **Step 4: Verify focused tests and build**

Run: `bin/rails test test/presenters/legal_case_show_snapshot_test.rb test/controllers/legal_cases_controller_test.rb && npm test -- app/frontend/legal_case_show/LegalCaseShowApp.test.tsx && bin/vite build --clear --mode=development`

Expected: PASS and manifest includes `entrypoints/legal_case_show.tsx`.

- [ ] **Step 5: Commit**

```bash
git add app/frontend/legal_case_show/legalCaseShow.css app/frontend/legal_case_show/LegalCaseShowApp.tsx app/views/legal_cases/show.html.erb app/views/layouts/application.html.erb test/controllers/legal_cases_controller_test.rb
git commit -m "feat: apply Aurora detail design"
```

### Task 4: Feature verification

**Files:**
- Modify: none

- [ ] **Step 1: Run Rails suite**

Run: `bin/rails test`

Expected: PASS.

- [ ] **Step 2: Run all frontend tests and Vite build**

Run: `npm test && bin/vite build --clear --mode=development`

Expected: PASS with dashboard, list and detail entrypoints.

- [ ] **Step 3: Inspect final diff**

Run: `git diff main...HEAD --check && git status --short`

Expected: no whitespace errors; report pre-existing `Gemfile.lock` and untracked plan files separately.
