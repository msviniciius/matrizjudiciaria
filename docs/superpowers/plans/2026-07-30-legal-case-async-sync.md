# Sincronização assíncrona do processo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Atualizar os andamentos de um processo sem navegar para outra página, com feedback de carregamento, mensagem do servidor e snapshot renovado.

**Architecture:** `LegalCasesController#sync` preserva os redirecionamentos HTML e passa a responder JSON para a chamada React. `LegalCaseShowApp` intercepta o envio, faz `POST` protegido por CSRF, mostra o estado ocupado no próprio botão e busca novamente apenas o snapshot JSON após êxito.

**Tech Stack:** Rails 8, Minitest, React, TypeScript, Vitest e Testing Library.

## Global Constraints

- Não alterar as regras de importação nem o escopo de escritório/unidade já aplicados por `set_legal_case`.
- Manter o fluxo HTML existente com `redirect_to`; o novo contrato é somente para `Accept: application/json`.
- Não usar polling nem recarregamento da janela.
- O botão deve permanecer acessível: desabilitado durante a chamada e acompanhado por texto de status.
- A animação respeita `prefers-reduced-motion`.

---

### Task 1: Contrato JSON da sincronização Rails

**Files:**
- Modify: `test/controllers/legal_cases_controller_test.rb:187-193`
- Modify: `app/controllers/legal_cases_controller.rb:73-93`

**Interfaces:**
- Consumes: `Pje::Ma::ImportCaseEventsJob.perform_now(legal_case_ids:, limit:)` e `@legal_case` já delimitado por unidade.
- Produces: `POST /legal_cases/:id/sync` com `Accept: application/json` responde `{ message: String }` em êxito e `{ error: String }` com status 422/500 em falha; HTML continua redirecionando.

- [ ] **Step 1: Write the failing test**

```ruby
test "sync returns JSON for the React detail screen" do
  Pje::Ma::ImportCaseEventsJob.stub(:perform_now, { imported: 1, skipped: 0 }) do
    post sync_legal_case_url(@legal_case), headers: { "ACCEPT" => "application/json" }
  end

  assert_response :success
  assert_equal "1 andamento(s) novo(s) importado(s) do CNJ. 0 já existiam.", response.parsed_body.fetch("message")
end

test "sync returns JSON validation feedback without an external number" do
  @legal_case.update!(external_number: "")

  post sync_legal_case_url(@legal_case), headers: { "ACCEPT" => "application/json" }

  assert_response :unprocessable_entity
  assert_equal "Este processo não possui número externo (CNJ) configurado.", response.parsed_body.fetch("error")
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/legal_cases_controller_test.rb`

Expected: the JSON assertions fail because `sync` redirects for every request.

- [ ] **Step 3: Write minimal implementation**

```ruby
def sync
  if @legal_case.external_number.blank?
    return respond_to do |format|
      format.html { redirect_to @legal_case, alert: "Este processo não possui número externo (CNJ) configurado." }
      format.json { render json: { error: "Este processo não possui número externo (CNJ) configurado." }, status: :unprocessable_entity }
    end
  end

  result = Pje::Ma::ImportCaseEventsJob.perform_now(legal_case_ids: [ @legal_case.id ], limit: 1)
  message, status = sync_feedback(result)
  respond_to do |format|
    format.html { redirect_to @legal_case, flash: { status => message } }
    format.json { render json: { message: message } }
  end
rescue => e
  Rails.logger.error "[PJE_MA] Erro na sincronização manual: #{e.message}"
  respond_to do |format|
    format.html { redirect_to @legal_case, alert: "Erro ao sincronizar: #{e.message}" }
    format.json { render json: { error: "Erro ao sincronizar: #{e.message}" }, status: :internal_server_error }
  end
end
```

Extract `sync_feedback(result)` as a private method returning the existing imported/skipped/empty copy plus `:notice` or `:alert`, so HTML and JSON use exactly the same outcome text.

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/controllers/legal_cases_controller_test.rb`

Expected: PASS, including existing HTML redirect coverage.

- [ ] **Step 5: Commit**

```bash
git add test/controllers/legal_cases_controller_test.rb app/controllers/legal_cases_controller.rb
git commit -m "feat: expose legal case sync as JSON"
```

### Task 2: Estado de sincronização no detalhe React

**Files:**
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx:1-190`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx:127-145, 258-305`
- Modify: `app/frontend/legal_case_show/legalCaseShow.css:7-13`

**Interfaces:**
- Consumes: `{ path: string, method: string }` em `snapshot.actions.sync` e a resposta JSON da Task 1.
- Produces: `SyncForm` chama `onSync(action)`, não envia formulário por navegação e apresenta `Buscando andamentos…` enquanto a promessa está pendente.

- [ ] **Step 1: Write the failing test**

```tsx
test("synchronizes from the detail screen without a page reload", async () => {
  const csrf = document.createElement("meta")
  csrf.name = "csrf-token"
  csrf.content = "csrf-detail-token"
  document.head.append(csrf)
  let resolveSync!: (response: unknown) => void
  const pendingSync = new Promise<unknown>((resolve) => { resolveSync = resolve })
  const refreshedSnapshot = snapshotWith([timelineItem(2, "Andamento importado")])
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockReturnValueOnce(pendingSync)
    .mockResolvedValueOnce(okResponse(refreshedSnapshot))
  vi.stubGlobal("fetch", fetchMock)

  render(<LegalCaseShowApp />)
  const user = userEvent.setup()
  const button = await screen.findByRole("button", { name: "Atualizar andamentos" })
  await user.click(button)
  expect(button).toBeDisabled()
  expect(button).toHaveTextContent("Buscando andamentos")

  resolveSync(okResponse({ message: "1 andamento novo importado." }))
  expect(await screen.findByRole("status")).toHaveTextContent("1 andamento novo importado.")
  expect(screen.getByText("Andamento importado")).toBeVisible()
  expect(fetchMock).toHaveBeenNthCalledWith(2, "/legal_cases/1/sync", expect.objectContaining({
    method: "POST", headers: expect.objectContaining({ "X-CSRF-Token": "csrf-detail-token" })
  }))
})
```

Add an `afterEach` cleanup for the test CSRF element. Add a separate failing response test asserting an alert and an enabled button after a non-OK JSON response.

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- LegalCaseShowApp.test.tsx`

Expected: FAIL because `SyncForm` submits a native form and exposes no pending/status state.

- [ ] **Step 3: Write minimal implementation**

```tsx
const syncCase = async (action: NonNullable<Snapshot["actions"]["sync"]>) => {
  const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
  const response = await fetch(action.path, {
    method: action.method.toUpperCase(),
    headers: { Accept: "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) }
  })
  const body = await response.json()
  if (!response.ok) throw new Error(body.error || "Não foi possível sincronizar os andamentos.")
  await loadSnapshot()
  setSyncMessage(body.message)
}
```

Keep `syncPending`, `syncError` and `syncMessage` in `LegalCaseShowApp`; pass a promise-returning `onSync` callback to `SyncForm`. In `SyncForm`, handle `onSubmit`, call `event.preventDefault()`, disable the button while pending, render a decorative spinner plus `Buscando andamentos…`, and announce the success/error from the parent with `role="status"`/`role="alert"`. Add CSS for the spinner using a keyframe rotation and an explicit `@media (prefers-reduced-motion: reduce)` rule that disables the animation.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- LegalCaseShowApp.test.tsx`

Expected: PASS, with the sync request carrying `Accept: application/json` and the CSRF header, followed by exactly one snapshot fetch.

- [ ] **Step 5: Commit**

```bash
git add app/frontend/legal_case_show/LegalCaseShowApp.test.tsx app/frontend/legal_case_show/LegalCaseShowApp.tsx app/frontend/legal_case_show/legalCaseShow.css
git commit -m "feat: sync legal case detail asynchronously"
```

### Task 3: Integração e qualidade

**Files:**
- Verify: `test/controllers/legal_cases_controller_test.rb`
- Verify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`
- Verify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Verify: `app/frontend/legal_case_show/legalCaseShow.css`

**Interfaces:**
- Consumes: os contratos JSON e React das Tasks 1 e 2.
- Produces: confirmação de que não há navegação de página e de que o build aceita o entrypoint atualizado.

- [ ] **Step 1: Run focused backend and frontend suites**

Run: `bin/rails test test/controllers/legal_cases_controller_test.rb && npm test -- LegalCaseShowApp.test.tsx`

Expected: PASS, sem falhas ou erros.

- [ ] **Step 2: Type-check and build the frontend**

Run: `npx tsc --noEmit && bin/vite build --mode=development`

Expected: ambos terminam com exit 0.

- [ ] **Step 3: Check the changed patch**

Run: `git diff --check HEAD~2..HEAD && git status --short`

Expected: sem erros de whitespace; somente alterações conscientemente não incluídas podem permanecer no status.

- [ ] **Step 4: Record the verification outcome**

Do not create a commit for verification alone. If a verification command fails, return to the task that owns the failing file, add a failing focused test when the failure represents uncovered behavior, then repeat that task's RED→GREEN cycle before running this task again.
