# Overlay glassmorphism da sincronização Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar um loader central de vidro durante a sincronização e eliminar o controle HTML duplicado que ainda recarrega a página.

**Architecture:** O estado `syncPending` já existente controla um overlay React fixo e modal, enquanto a ação Rails redundante do topbar é removida. O overlay anuncia o andamento, bloqueia o fundo e desaparece após êxito ou falha; a sincronização continua usando o mesmo `POST` JSON.

**Tech Stack:** Rails ERB, React, TypeScript, CSS, Vitest e Testing Library.

## Global Constraints

- Não alterar o endpoint, importação, escopo de escritório/unidade ou o contrato JSON.
- Não usar polling ou recarregamento de página.
- Exibir somente um controle visível de sincronização: o React no painel lateral.
- Respeitar `prefers-reduced-motion`, anunciar o estado e impedir interações de fundo durante a atualização.

---

### Task 1: Controle único e overlay glassmorphism

**Files:**
- Modify: `app/views/legal_cases/show.html.erb:1-8`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx:170-255`
- Modify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx:155-185`
- Modify: `app/frontend/legal_case_show/legalCaseShow.css:1-20`

**Interfaces:**
- Consumes: `syncPending: boolean` e a função assíncrona `syncCase(action)`.
- Produces: um overlay `role="status"` com texto `Buscando andamentos…`, sem controles concorrentes em ERB e sem navegação nativa.

- [ ] **Step 1: Write the failing test**

```tsx
await user.click(await screen.findByRole("button", { name: "Atualizar andamentos" }))
expect(screen.getByRole("status", { name: /buscando andamentos/i })).toBeVisible()
expect(screen.getByTestId("legal-case-sync-overlay")).toHaveAttribute("aria-busy", "true")
expect(screen.getByTestId("legal-case-sync-overlay")).toHaveTextContent("Buscando andamentos…")
```

Also assert the overlay disappears after resolving the sync response. Add an ERB view assertion that `show.html.erb` no longer contains `sync_legal_case_path` or `button_to` for synchronization.

- [ ] **Step 2: Run the focused tests to verify RED**

Run: `npm test -- LegalCaseShowApp.test.tsx`

Expected: FAIL because the current pending state only changes the rail button and has no central overlay.

- [ ] **Step 3: Write the minimal implementation**

```tsx
{syncPending && <section
  className="react-legal-case-show__sync-overlay"
  data-testid="legal-case-sync-overlay"
  role="status"
  aria-live="polite"
  aria-busy="true"
  aria-label="Buscando andamentos"
>
  <div className="react-legal-case-show__sync-glass">
    <span className="react-legal-case-show__sync-spinner" aria-hidden="true" />
    <p>Buscando andamentos…</p>
  </div>
</section>}
```

Remove the topbar synchronization `button_to` from `show.html.erb`. Style the overlay as a fixed full-viewport backdrop with translucent dark blue, `backdrop-filter: blur(...)`, a raised translucent glass card, and a high `z-index`. Keep the spinner decorative and disable its animation under the existing reduced-motion media query.

- [ ] **Step 4: Run tests to verify GREEN**

Run: `npm test -- LegalCaseShowApp.test.tsx`

Expected: PASS; six existing behaviors plus the overlay behavior remain green.

- [ ] **Step 5: Commit**

```bash
git add app/views/legal_cases/show.html.erb app/frontend/legal_case_show/LegalCaseShowApp.test.tsx app/frontend/legal_case_show/LegalCaseShowApp.tsx app/frontend/legal_case_show/legalCaseShow.css
git commit -m "feat: show glass loader during legal case sync"
```

### Task 2: Verification

**Files:**
- Verify: `app/views/legal_cases/show.html.erb`
- Verify: `app/frontend/legal_case_show/LegalCaseShowApp.test.tsx`
- Verify: `app/frontend/legal_case_show/LegalCaseShowApp.tsx`
- Verify: `app/frontend/legal_case_show/legalCaseShow.css`

**Interfaces:**
- Consumes: the single React synchronization control and its pending state.
- Produces: verification that the screen builds and has no whitespace errors.

- [ ] **Step 1: Run the focused frontend test**

Run: `npm test -- LegalCaseShowApp.test.tsx`

Expected: PASS with the overlay test.

- [ ] **Step 2: Build the Vite entries**

Run: `bin/vite build --mode=development`

Expected: exit 0.

- [ ] **Step 3: Inspect the patch**

Run: `git diff --check HEAD~1..HEAD && git status --short`

Expected: no whitespace errors; any pre-existing `Gemfile.lock`, header/label React changes, and unrelated plan files remain uncommitted.

