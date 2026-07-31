# Listagem de Clientes Aurora Implementation Plan

> For agentic workers: use superpowers:subagent-driven-development or superpowers:executing-plans. Execute each checkbox task with TDD and review.

**Goal:** Transformar /clients em uma listagem React assíncrona que reproduza o padrão visual de processos, preservando ações e escopo existentes.

**Architecture:** ClientsController#index fornecerá snapshot JSON autorizado por escritório/unidade. Um entrypoint React específico usará a mesma composição de cabeçalho, filtros, alternância cards/tabela, loading, erro e estado vazio de processos.

**Tech Stack:** Rails 8, Minitest, React, TypeScript, Vite, Vitest e Testing Library.

## Global Constraints

- Preservar scope_by_current_unit(current_office.clients) e ações Rails autorizadas.
- Não remover visualizar, editar, excluir ou acesso aos processos do cliente.
- Não usar polling, edição inline ou recarregamento da página para filtros.
- Manter fallback HTML e a rota /clients funcionando.
- Usar labels, aria-pressed, role=status, role=alert, foco visível e reduced motion.

---

### Task 1: Snapshot JSON de clientes

**Files:** app/controllers/clients_controller.rb, app/views/clients/index.html.erb, app/views/layouts/application.html.erb, test/controllers/clients_controller_test.rb, app/presenters/clients_snapshot.rb.

**Interface:** GET /clients.json responde:
{
  "meta": { "office_name": "string", "unit_name": "string|null", "total_count": 0 },
  "filters": { "q": "", "cadastro_pendente": "", "city": "" },
  "clients": [{ "id": 1, "path": "/clients/1", "edit_path": "/clients/1/edit", "delete_path": "/clients/1", "full_name": "string", "cpf_cnpj": "string", "phone": "string", "email": "string", "city": "string", "cadastro_pendente": false, "status_label": "Completo", "legal_cases_count": 0, "processes_path": "/clients/1" }],
  "actions": { "index": "/clients", "new": "/clients/new" }
}

- [ ] Write failing Rails tests proving the JSON response is structured, includes the active-unit client and process count, and excludes a client from another unit.
- [ ] Run: source .env && bin/rails test test/controllers/clients_controller_test.rb. Expect failure because the current JSON view returns an array.
- [ ] Add ClientsSnapshot#as_json and make ClientsController#index render it for JSON while retaining the filtered HTML scope and fallback.
- [ ] Run the focused Rails test again; expect all tests to pass.
- [ ] Commit: feat: expose clients listing snapshot.

### Task 2: React clients listing

**Files:** create app/frontend/clients/ClientsApp.tsx, app/frontend/clients/clients.css, app/frontend/entrypoints/clients.tsx and app/frontend/clients/ClientsApp.test.tsx; modify app/views/clients/index.html.erb and existing Vite entry mapping.

**Interface:** consumes the Task 1 snapshot and renders cards or table with client actions.

- [ ] Write failing component tests for cards with status/process count, table switching, async search, loading skeleton, retry, empty state, persisted table preference and visual/edit/delete/process actions.
- [ ] Run: npm test -- ClientsApp.test.tsx. Expect failure because the entrypoint does not exist.
- [ ] Implement the component by following LegalCasesApp: View cards/table, sessionStorage key clients-view, URLSearchParams for q/cadastro_pendente/city, AbortController for stale requests, Aurora shell, responsive cards/table, badges, loading/error/empty states and authorized Rails action paths.
- [ ] Preserve destructive delete semantics with CSRF and confirmation; do not invent client mutations in React.
- [ ] Run npm test -- ClientsApp.test.tsx and expect all tests to pass.
- [ ] Run bin/vite build --mode=development and expect exit 0.
- [ ] Commit: feat: add aurora clients listing.

### Task 3: Integration verification

- [ ] Run source .env && bin/rails test test/controllers/clients_controller_test.rb && npm test.
- [ ] Run bin/vite build --mode=development.
- [ ] Run git diff --check and confirm only pre-existing Gemfile.lock/plans remain outside the commits.

