import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { LegalCasesApp } from "./LegalCasesApp"

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
  responsible_name: "Marina",
  last_movement: "Petição protocolada",
  next_deadline_on: "2026-07-30",
  next_deadline_label: "30/07",
  deadline_tone: "upcoming",
  has_new_imported_events: false
}]) => ({
  meta: { office_name: "Aurora Advocacia", unit_name: "Contencioso", total_count: legalCases.length },
  filters: { q: "", phase: "", status: "", priority: "", responsible_name: "", deadline_state: "" },
  filter_options: {
    q: [],
    phase: [{ label: "Análise jurídica", value: "analise_juridica" }],
    status: [{ label: "Em análise", value: "em_analise" }],
    priority: [{ label: "Alta", value: "high" }],
    responsible_name: [],
    deadline_state: [{ label: "Atrasado", value: "overdue" }]
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

test("offers an empty-state message and filter reset when no cases match", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith("", []))))

  render(<LegalCasesApp />)

  expect(await screen.findByText("Nenhum processo encontrado para estes filtros.")).toBeVisible()
  expect(screen.getByRole("status")).toHaveTextContent("0 processo(s)")
  expect(screen.getByRole("button", { name: "Limpar filtros" })).toBeVisible()
})
