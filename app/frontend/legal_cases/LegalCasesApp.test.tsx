import "@testing-library/jest-dom/vitest"
import { act, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { LegalCasesApp } from "./LegalCasesApp"

test("uses the containing Rails main landmark without nesting another main", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("PROC-MAIN"))))

  const { container } = render(<main><LegalCasesApp /></main>)

  await screen.findByRole("link", { name: /PROC-MAIN/ })
  expect(container.querySelectorAll("main")).toHaveLength(1)
  expect(container.querySelector(".react-legal-cases")?.tagName).toBe("DIV")
})

const snapshotWith = (internalNumber: string, legalCases = [{
  id: 1,
  path: "/processos/1",
  internal_number: internalNumber,
  client_name: "Cliente Aurora",
  legal_area_name: "Cível",
  status: "em_analise",
  status_label: "Em análise",
  phase: "analise_juridica",
  priority: "high",
  priority_label: "Alta",
  responsible_name: "Marina",
  last_movement: "Petição protocolada",
  next_deadline_on: "2026-07-30",
  next_deadline_label: "30/07",
  deadline_tone: "upcoming",
  has_new_imported_events: false
}]) => ({
  meta: { office_name: "Aurora Advocacia", unit_name: "Contencioso", total_count: legalCases.length },
  filters: { q: "", phase: "", status: "", priority: "", responsible_name: "", deadline_state: "", health: "", without_next_action: "", operational: "" },
  filter_options: {
    q: [],
    phase: [{ label: "Análise jurídica", value: "analise_juridica" }],
    status: [{ label: "Em análise", value: "em_analise" }],
    priority: [{ label: "Alta", value: "high" }],
    responsible_name: [],
    deadline_state: [{ label: "Atrasado", value: "overdue" }],
    health: [],
    without_next_action: [],
    operational: []
  },
  legal_cases: legalCases,
  actions: { index: "/processos", new: "/processos/novo", daily_closure: "/processos/fechamento_diario" }
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  sessionStorage.clear()
  window.history.replaceState({}, "", "/processos")
})

test("loads operational cards and replaces the URL after an async filter", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-001")))
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-002"))))

  render(<LegalCasesApp />)
  expect(screen.getByRole("status")).toHaveTextContent("Carregando processos")
  expect(await screen.findByRole("link", { name: /PROC-001/ })).toBeVisible()

  await userEvent.setup().click(screen.getByRole("button", { name: "Filtros avançados" }))
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
  await userEvent.setup().click(screen.getByRole("button", { name: "Filtros avançados" }))
  await userEvent.setup().selectOptions(screen.getByLabelText("Status"), "em_analise")
  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  expect(screen.getByRole("link", { name: /PROC-001/ })).toBeVisible()
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByRole("link", { name: /PROC-002/ })).toBeVisible()
})

test("offers an empty-state message and filter reset when no cases match", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("", []))))

  render(<LegalCasesApp />)

  expect(await screen.findByText("Nenhum processo encontrado para estes filtros.")).toBeVisible()
  expect(screen.getByRole("status")).toHaveTextContent("0 processo(s)")
  expect(screen.getByRole("button", { name: "Limpar filtros" })).toBeVisible()
})

test("keeps search visible and exposes advanced filters with accessible state", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("PROC-001"))))

  render(<LegalCasesApp />)
  await screen.findByRole("link", { name: /PROC-001/ })
  const search = screen.getByLabelText("Busca")
  const toggle = screen.getByRole("button", { name: "Filtros avançados" })
  const controls = toggle.getAttribute("aria-controls")

  expect(search).toBeVisible()
  expect(toggle).toHaveAttribute("aria-expanded", "false")
  expect(controls).toBeTruthy()
  expect(document.getElementById(controls!)).not.toBeVisible()

  await userEvent.setup().click(toggle)

  expect(toggle).toHaveAttribute("aria-expanded", "true")
  expect(document.getElementById(controls!)).toBeVisible()
  expect(screen.getByLabelText("Status")).toBeVisible()
})

test("applies the search draft only when the form is submitted", async () => {
  const searchedSnapshot = snapshotWith("PROC-SEARCH")
  searchedSnapshot.filters.q = "ação urgente"
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-001")))
    .mockResolvedValue(okResponse(searchedSnapshot))
  vi.stubGlobal("fetch", fetchMock)

  render(<LegalCasesApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: /PROC-001/ })
  await user.type(screen.getByLabelText("Busca"), "ação urgente")

  expect(fetchMock).toHaveBeenCalledTimes(1)
  expect(new URLSearchParams(window.location.search).get("q")).toBeNull()

  await user.click(screen.getByRole("button", { name: "Buscar" }))

  expect(await screen.findByRole("link", { name: /PROC-SEARCH/ })).toBeVisible()
  expect(fetchMock).toHaveBeenCalledTimes(2)
  expect(new URLSearchParams(window.location.search).get("q")).toBe("ação urgente")
})

test("ignores an older filter response that arrives after the latest result", async () => {
  type Deferred = { promise: Promise<unknown>; resolve: (value: unknown) => void }
  const deferred = (): Deferred => {
    let resolve!: (value: unknown) => void
    const promise = new Promise<unknown>((next) => { resolve = next })
    return { promise, resolve }
  }
  const older = deferred()
  const latest = deferred()
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith("PROC-INITIAL")))
    .mockReturnValueOnce(older.promise)
    .mockReturnValueOnce(latest.promise)
  vi.stubGlobal("fetch", fetchMock)

  render(<LegalCasesApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: /PROC-INITIAL/ })
  await user.click(screen.getByRole("button", { name: "Filtros avançados" }))
  await user.selectOptions(screen.getByLabelText("Status"), "em_analise")
  await user.selectOptions(screen.getByLabelText("Fase"), "analise_juridica")

  await act(async () => {
    latest.resolve(okResponse(snapshotWith("PROC-LATEST")))
  })
  expect(await screen.findByRole("link", { name: /PROC-LATEST/ })).toBeVisible()

  await act(async () => {
    older.resolve(okResponse(snapshotWith("PROC-OLDER")))
  })
  expect(screen.queryByRole("link", { name: /PROC-OLDER/ })).not.toBeInTheDocument()
  expect(screen.getByRole("link", { name: /PROC-LATEST/ })).toBeVisible()
})

test("displays the localized priority label", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("PROC-001"))))

  render(<LegalCasesApp />)

  const legalCase = await screen.findByRole("link", { name: /PROC-001/ })
  expect(legalCase).toHaveTextContent("Prioridade Alta")
  expect(legalCase).not.toHaveTextContent("Prioridade high")
})

test("preserves Rails-owned contextual filters in the initial JSON request", async () => {
  window.history.replaceState({}, "", "/processos?health=critica&operational=1")
  const fetchMock = vi.fn().mockResolvedValue(okResponse(snapshotWith("PROC-RISK")))
  vi.stubGlobal("fetch", fetchMock)

  render(<LegalCasesApp />)

  await screen.findByRole("link", { name: /PROC-RISK/ })
  expect(fetchMock).toHaveBeenCalledWith(
    "/legal_cases.json?health=critica&operational=1",
    expect.objectContaining({ headers: { Accept: "application/json" } })
  )
})
