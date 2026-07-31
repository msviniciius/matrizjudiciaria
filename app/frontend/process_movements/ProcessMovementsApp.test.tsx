import "@testing-library/jest-dom/vitest"
import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { ProcessMovementsApp } from "./ProcessMovementsApp"

const movementWith = (title: string, overrides = {}) => ({
  id: 1,
  path: "/process_movements/1",
  edit_path: "/process_movements/1/edit",
  legal_case_path: "/legal_cases/1",
  process_number: "PROC-001",
  client_name: "Cliente Aurora",
  phase_name: "Análise jurídica",
  status_label: "Em análise",
  movement_type_name: "Petição",
  display_title: title,
  description: "Descrição do andamento",
  event_date_label: "30/07/2026 10:00",
  nature_label: "Fato processual",
  impact_label: "Sem impacto de fase",
  origin_label: "Manual",
  administrative_situation_label: "Em análise",
  responsible_name: "Marina",
  ...overrides
})

const options = {
  phases: [{ value: "1", label: "Análise jurídica" }],
  statuses: [{ value: "em_analise", label: "Em análise" }],
  movement_types: [{ value: "1", label: "Petição" }],
  natures: [{ value: "fato_processual", label: "Fato processual" }],
  impacts: [{ value: "sem_impacto_de_fase", label: "Sem impacto de fase" }],
  origins: [{ value: "manual", label: "Manual" }],
  exams: [{ value: "1", label: "Perícia médica" }],
  administrative_situations: [{ value: "em_analise", label: "Em análise" }]
}

const reports = {
  por_fase: { title: "Por fase", total: 2, entries: [{ label: "Análise jurídica", count: 2 }] },
  por_tipo: { title: "Por tipo", total: 2, entries: [{ label: "Petição", count: 2 }] },
  por_natureza: { title: "Por natureza", total: 2, entries: [{ label: "Fato processual", count: 2 }] },
  por_impacto: { title: "Por impacto", total: 2, entries: [{ label: "Sem impacto de fase", count: 2 }] },
  por_origem: { title: "Por origem", total: 2, entries: [{ label: "Manual", count: 2 }] }
}

const snapshotWith = (movements = [movementWith("Petição juntada")]) => ({
  meta: { office_name: "Aurora Advocacia", total_count: movements.length },
  filters: { q: "", phase_id: "", status: "", movement_type_id: "", nature: "", impact: "", origin: "", from: "", to: "", responsible_name: "", exam_id: "", administrative_situation: "" },
  filter_options: options,
  reports,
  process_movements: movements,
  actions: { index: "/process_movements", new: "/process_movements/new" }
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  sessionStorage.clear()
  window.history.replaceState({}, "", "/process_movements")
})

test("renders reports and movement cards in the clients listing pattern", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<ProcessMovementsApp />)

  expect(await screen.findByRole("heading", { name: "Andamentos processuais" })).toBeVisible()
  expect(screen.getByRole("heading", { name: "Relatórios" })).toBeVisible()
  expect(screen.getByText("Por fase")).toBeVisible()
  expect(screen.getByRole("article", { name: "Petição juntada" })).toHaveTextContent("Cliente Aurora")
  expect(screen.getByRole("link", { name: "Novo andamento" })).toHaveAttribute("href", "/process_movements/new")
})

test("switches to table view and keeps action links compact", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<ProcessMovementsApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Tabela" }))

  expect(screen.getByRole("table", { name: "Listagem de andamentos processuais" })).toBeVisible()
  expect(screen.getByRole("link", { name: "Ver andamento Petição juntada" })).toHaveAttribute("href", "/process_movements/1")
  expect(sessionStorage.getItem("process-movements-view")).toBe("table")
})

test("updates filters asynchronously and preserves report rendering", async () => {
  const searched = snapshotWith([movementWith("Andamento filtrado")])
  searched.filters.q = "filtrado"
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockResolvedValueOnce(okResponse(searched))
    .mockResolvedValueOnce(okResponse(searched))
  vi.stubGlobal("fetch", fetchMock)

  render(<ProcessMovementsApp />)
  const user = userEvent.setup()
  await screen.findByText("Petição juntada")
  await user.type(screen.getByLabelText("Busca"), "filtrado")
  await user.click(screen.getByRole("button", { name: "Buscar" }))

  expect(await screen.findByText("Andamento filtrado")).toBeVisible()
  expect(new URLSearchParams(window.location.search).get("q")).toBe("filtrado")
  await user.click(screen.getByRole("button", { name: "Filtros avançados" }))
  fireEvent.change(screen.getByLabelText("Fase"), { target: { value: "1" } })
  expect(await screen.findByRole("heading", { name: "Relatórios" })).toBeVisible()
})

test("shows error retry and empty state", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith([])))
  )

  render(<ProcessMovementsApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByText("Nenhum andamento processual encontrado.")).toBeVisible()
})
