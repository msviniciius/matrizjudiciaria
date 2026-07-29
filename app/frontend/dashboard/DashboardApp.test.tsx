import "@testing-library/jest-dom/vitest"
import { fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { DashboardApp } from "./DashboardApp"

test("shows an accessible loading state before the dashboard snapshot arrives", () => {
  render(<DashboardApp />)

  expect(screen.getByRole("status")).toHaveTextContent("Carregando painel")
})

afterEach(() => {
  vi.unstubAllGlobals()
})

test("renders the command center from the server snapshot", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({
      meta: { office_name: "Kayran Advocacia", unit_name: "Centro", syncable_count: 2, new_imported_events_count: 1 },
      kpis: {
        due_today: { label: "Prazos hoje", count: 3, path: "/prazos?due_state=today", tone: "warning" }
      },
      critical_queues: {
        without_responsible: [{ id: 1, internal_number: "SEI01", path: "/processos/1", responsible_name: "", updated_at: "2026-07-29T12:00:00Z", update_responsible_path: "/painel/processos/1/responsavel" }],
        without_next_action: [],
        overdue_deadlines_without_reason: []
      },
      risk_queue: {},
      feed: [{ title: "Protocolar manifestação", origin: "Prazo", internal_number: "SEI01", highlight: true, path: "/processos/1" }],
      distribution: {
        phase: [{ label: "Análise jurídica", count: 2, path: "/processos?phase=analise_juridica" }],
        status: [{ label: "Em análise", count: 4, path: "/processos?status=em_analise" }]
      },
      actions: { sync: "/painel/sync" }
    })
  }))

  render(<DashboardApp />)

  expect(await screen.findByRole("heading", { name: "Fila de atenção" })).toBeVisible()
  expect(screen.getByRole("heading", { name: "Próxima ação" })).toBeVisible()
  expect(screen.getByRole("link", { name: /Prazos hoje.*3/ })).toHaveAttribute("href", "/prazos?due_state=today")
  expect(within(screen.getByRole("region", { name: "Próxima ação" })).getByRole("link", { name: /Protocolar manifestação/ })).toHaveAttribute("href", "/processos/1")
  expect(screen.getByText("Processos sem responsável")).toBeVisible()
  expect(screen.getByRole("link", { name: /^SEI01/ })).toHaveAttribute("href", "/processos/1")
  expect(screen.getByRole("img", { name: "Distribuição por status" })).toBeVisible()
  expect(screen.getByRole("img", { name: "Distribuição por fase" })).toBeVisible()
  expect(screen.getByRole("button", { name: "Em análise: 4 processos" })).toBeVisible()
  expect(screen.getByRole("button", { name: "Análise jurídica: 2 processos" })).toBeVisible()
  expect(screen.getByRole("img", { name: "Distribuição por status" }).querySelector("circle")).toHaveAttribute("pathLength", "100")
  await waitFor(() => expect(screen.queryByRole("status", { name: /carregando/i })).not.toBeInTheDocument())
})

test("activates a chart filter with the keyboard", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({
      meta: { office_name: "Kayran Advocacia", syncable_count: 0, new_imported_events_count: 0 },
      kpis: {}, critical_queues: { without_responsible: [], without_next_action: [], overdue_deadlines_without_reason: [] }, risk_queue: {}, feed: [],
      distribution: {
        phase: [],
        status: [{ label: "Em análise", count: 4, path: "/processos?status=em_analise" }]
      },
      actions: { sync: "/painel/sync" }
    })
  }))

  render(<DashboardApp />)
  const user = userEvent.setup()
  const filter = await screen.findByRole("button", { name: "Em análise: 4 processos" })

  filter.focus()
  await user.keyboard("{Enter}")

  expect(screen.getByRole("status")).toHaveTextContent("Filtro selecionado: Em análise (4 processos)")
  expect(filter).toHaveAttribute("aria-pressed", "true")
  expect(screen.getByRole("link", { name: "Abrir processos filtrados" })).toHaveAttribute("href", "/processos?status=em_analise")
})

test("keeps a KPI selection in the dashboard and exposes its Rails path", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({
      meta: { office_name: "Kayran Advocacia", syncable_count: 0, new_imported_events_count: 0 },
      kpis: { due_today: { label: "Prazos hoje", count: 3, path: "/prazos?due_state=today", tone: "warning" } },
      critical_queues: { without_responsible: [], without_next_action: [], overdue_deadlines_without_reason: [] }, risk_queue: {}, feed: [], distribution: { phase: [], status: [] }, actions: { sync: "/painel/sync" }
    })
  }))

  render(<DashboardApp />)
  const kpi = await screen.findByRole("link", { name: /Prazos hoje.*3/ })

  expect(fireEvent.click(kpi)).toBe(false)
  expect(screen.getByRole("status")).toHaveTextContent("Filtro selecionado: Prazos hoje (3 processos)")
  expect(screen.getByRole("link", { name: "Abrir processos filtrados" })).toHaveAttribute("href", "/prazos?due_state=today")
})

test("opens a contextual panel for a KPI and keeps its selected filter after closing", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({
      meta: { office_name: "Kayran Advocacia", syncable_count: 0, new_imported_events_count: 0 },
      kpis: { due_today: { label: "Prazos hoje", count: 3, path: "/prazos?due_state=today", tone: "warning" } },
      critical_queues: { without_responsible: [], without_next_action: [], overdue_deadlines_without_reason: [] }, risk_queue: {}, feed: [], distribution: { phase: [], status: [] }, actions: { sync: "/painel/sync" }
    })
  }))

  render(<DashboardApp />)
  const user = userEvent.setup()
  await user.click(await screen.findByRole("link", { name: /Prazos hoje.*3/ }))

  const panel = screen.getByRole("dialog", { name: "Detalhes do filtro: Prazos hoje" })
  expect(within(panel).getByRole("heading", { name: "Detalhes do filtro: Prazos hoje" })).toBeVisible()
  expect(within(panel).getByText("3 processos")).toBeVisible()
  expect(within(panel).getByRole("link", { name: "Ver processos filtrados" })).toHaveAttribute("href", "/prazos?due_state=today")
  await user.click(within(panel).getByRole("button", { name: "Fechar painel" }))

  expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  expect(screen.getByRole("status")).toHaveTextContent("Filtro selecionado: Prazos hoje (3 processos)")
})

test("updates a responsible person and confirms without reloading the page", async () => {
  const snapshot = {
    meta: { office_name: "Kayran Advocacia", unit_name: "Centro", syncable_count: 2, new_imported_events_count: 0 }, kpis: {},
    critical_queues: { without_responsible: [{ id: 1, internal_number: "SEI01", path: "/processos/1", responsible_name: "", updated_at: "2026-07-29T12:00:00Z", update_responsible_path: "/painel/processos/1/responsavel" }], without_next_action: [], overdue_deadlines_without_reason: [] },
    risk_queue: {}, feed: [], distribution: { phase: [], status: [] }, actions: { sync: "/painel/sync" }
  }
  const resolvedSnapshot = { ...snapshot, critical_queues: { ...snapshot.critical_queues, without_responsible: [] } }
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce({ ok: true, json: async () => snapshot })
    .mockResolvedValueOnce({ ok: true, json: async () => ({ message: "Responsável do processo atualizado." }) })
    .mockResolvedValueOnce({ ok: true, json: async () => resolvedSnapshot }))

  render(<DashboardApp />)
  const user = userEvent.setup()
  await user.type(await screen.findByLabelText("Responsável do processo SEI01"), "Marina")
  await user.click(screen.getByRole("button", { name: "Salvar responsável" }))

  expect(await screen.findByRole("status")).toHaveTextContent("Responsável do processo atualizado.")
  expect(screen.queryByRole("link", { name: /^SEI01/ })).not.toBeInTheDocument()
})
