import "@testing-library/jest-dom/vitest"
import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { DeadlinesApp } from "./DeadlinesApp"

const deadlineWith = (title: string, overrides = {}) => ({
  id: 1,
  path: "/deadlines/1",
  edit_path: "/deadlines/1/edit",
  delete_path: "/deadlines/1",
  legal_case_path: "/legal_cases/1",
  process_number: "PROC-001",
  client_name: "Cliente Aurora",
  title,
  deadline_type_label: "Judicial",
  due_date_label: "30/07/2026",
  due_state: "today",
  due_state_label: "Hoje",
  status: "pending",
  status_label: "Pendente",
  priority: "medium",
  priority_label: "Média",
  extended_at_label: "-",
  responsible_name: "Marina",
  delay_reason: "",
  ...overrides
})

const filterOptions = {
  statuses: [{ value: "pending", label: "Pendente" }],
  priorities: [{ value: "medium", label: "Média" }],
  deadline_types: [{ value: "judicial", label: "Judicial" }],
  due_states: [{ value: "today", label: "Hoje" }]
}

const snapshotWith = (deadlines = [deadlineWith("Prazo inicial")]) => ({
  meta: { office_name: "Aurora Advocacia", unit_name: "Contencioso", total_count: deadlines.length },
  filters: { q: "", status: "", priority: "", deadline_type: "", due_state: "" },
  filter_options: filterOptions,
  deadlines,
  actions: { index: "/deadlines", new: "/deadlines/new" }
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  sessionStorage.clear()
  window.history.replaceState({}, "", "/deadlines")
})

test("loads deadline cards with status and edit/delete actions", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<DeadlinesApp />)

  const card = await screen.findByRole("article", { name: /Prazo inicial/ })
  expect(card).toHaveTextContent("Hoje")
  expect(card).toHaveTextContent("Cliente Aurora")
  expect(screen.getByRole("link", { name: "Prazo inicial" })).toHaveAttribute("href", "/deadlines/1")
  expect(screen.getByRole("link", { name: "Editar prazo Prazo inicial" })).toHaveAttribute("href", "/deadlines/1/edit")
  expect(screen.getByRole("button", { name: "Excluir prazo Prazo inicial" })).toBeVisible()
})

test("switches to table view and stores the preference", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<DeadlinesApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Tabela" }))

  expect(screen.getByRole("table", { name: "Listagem de prazos" })).toBeVisible()
  expect(sessionStorage.getItem("deadlines-view")).toBe("table")
})

test("submits async search and advanced filters", async () => {
  const searched = snapshotWith([deadlineWith("Prazo pesquisado")])
  searched.filters.q = "pesquisado"
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockResolvedValueOnce(okResponse(searched))
    .mockResolvedValueOnce(okResponse(searched))
  vi.stubGlobal("fetch", fetchMock)

  render(<DeadlinesApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: "Prazo inicial" })
  await user.type(screen.getByLabelText("Busca"), "pesquisado")
  await user.click(screen.getByRole("button", { name: "Buscar" }))

  expect(await screen.findByRole("link", { name: "Prazo pesquisado" })).toBeVisible()
  expect(new URLSearchParams(window.location.search).get("q")).toBe("pesquisado")
  await user.click(screen.getByRole("button", { name: "Filtros avançados" }))
  fireEvent.change(screen.getByLabelText("Status"), { target: { value: "pending" } })
  expect(await screen.findByRole("heading", { name: "Prazos" })).toBeVisible()
})

test("shows error retry and empty state", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith([])))
  )

  render(<DeadlinesApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByText("Nenhum prazo encontrado para estes filtros.")).toBeVisible()
})

test("uses CSRF confirmation semantics before submitting deadline deletion", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))
  const csrf = document.createElement("meta")
  csrf.name = "csrf-token"
  csrf.content = "csrf-deadlines-token"
  document.head.append(csrf)
  const confirmMock = vi.spyOn(window, "confirm").mockReturnValue(false)

  render(<DeadlinesApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Excluir prazo Prazo inicial" }))

  expect(confirmMock).toHaveBeenCalledWith("Excluir este prazo?")
  expect(screen.getByRole("button", { name: "Excluir prazo Prazo inicial" }).closest("form")).toHaveAttribute("action", "/deadlines/1")
  csrf.remove()
})
