import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { LegalCaseShowApp } from "./LegalCaseShowApp"

const timelineItem = (id: number, title: string) => ({
  id,
  source: "process_movement",
  source_label: "Andamento",
  title,
  description: "Descrição do andamento",
  occurred_at: "2026-07-30",
  occurred_at_label: "30/07/2026",
  movement_type: "Petição",
  origin: null,
  highlight: id === 1,
  nature: null,
  administrative_situation: null,
  exam_summary: null
})

const snapshotWith = (timeline = [timelineItem(1, "Andamento recente")]) => ({
  case: {
    id: 1,
    internal_number: "PROC-001",
    external_number: "0000001-00.2026.8.10.0001",
    client_name: "Cliente Aurora",
    phase: "analise_juridica",
    phase_label: "Análise jurídica",
    status: "em_analise",
    status_label: "Em análise",
    priority: "high",
    priority_label: "Alta",
    responsible_name: "Marina",
    legal_area_name: "Cível",
    process_type_name: "Conhecimento",
    court_name: "1ª Vara Cível",
    district_name: "São Luís",
    claim_value: "1000.0",
    opposing_party: "Parte contrária",
    tem_pericia: true
  },
  alerts: {
    deadline_near: true,
    deadline_overdue: false,
    exam_pending: false,
    next_action_warning: false,
    stale_last_movement: false,
    health_status: "amarelo",
    has_new_imported_events: false
  },
  next_action: {
    description: "Protocolar manifestação",
    deadline_on: "2026-07-31",
    deadline_label: "31/07/2026",
    last_movement_at: "2026-07-30",
    last_movement_label: "30/07/2026"
  },
  timeline,
  deadlines: [{
    id: 1,
    title: "Prazo processual",
    due_date: "2026-07-31",
    due_date_label: "31/07/2026",
    status: "pending",
    status_label: "Pendente",
    priority: "high",
    priority_label: "Alta",
    deadline_type: "judicial",
    deadline_type_label: "Judicial",
    responsible_name: "Marina",
    delay_reason: "-",
    path: "/deadlines/1"
  }],
  tasks: [{
    id: 1,
    title: "Revisar documentos",
    description: "",
    due_date: "2026-08-01",
    due_date_label: "01/08/2026",
    status: "pending",
    status_label: "Pendente",
    priority: "medium",
    priority_label: "Média",
    responsible_name: "Marina",
    path: "/tasks/1"
  }],
  exams: [{
    id: 1,
    nature: "medica",
    nature_label: "Médica",
    scope: "judicial",
    scope_label: "Judicial",
    scheduled_at: "2026-08-02",
    scheduled_label: "02/08/2026",
    status: "designada",
    status_label: "Designada",
    location: "Fórum",
    expert_name: "Dr. Silva",
    notes: "",
    active: true,
    path: "/process_exams/1/edit"
  }],
  actions: {
    index: "/legal_cases",
    edit: "/legal_cases/1/edit",
    pdf: "/legal_cases/1/pdf",
    calendar: "/legal_cases/1/google_calendar",
    new_movement: "/process_movements/new?process_id=1",
    new_deadline: "/deadlines/new?legal_case_id=1",
    new_task: "/tasks/new?legal_case_id=1",
    new_exam: "/legal_cases/1/process_exams/new",
    sync: { path: "/legal_cases/1/sync", method: "post" }
  }
})

const alertedSnapshot = snapshotWith()
const snapshotWithSixTimelineItems = snapshotWith([
  timelineItem(1, "Andamento 1"),
  timelineItem(2, "Andamento 2"),
  timelineItem(3, "Andamento 3"),
  timelineItem(4, "Andamento 4"),
  timelineItem(5, "Andamento 5"),
  timelineItem(6, "Andamento antigo")
])
const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  document.querySelector('meta[name="csrf-token"]')?.remove()
  window.history.replaceState({}, "", "/")
})

test("renders the command center and opens an alerted deadline section", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Cliente Aurora" })).toBeVisible()
  expect(screen.getByRole("region", { name: "Central de comando" })).toBeVisible()
  expect(screen.queryByRole("main")).not.toBeInTheDocument()
  expect(screen.getByRole("button", { name: /Prazos/ })).toHaveAttribute("aria-expanded", "true")
  expect(screen.queryByRole("link", { name: "Editar processo" })).not.toBeInTheDocument()
})

test("describes an empty timeline and exposes each operational section through a heading toggle", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith([]))))
  render(<LegalCaseShowApp />)

  expect(await screen.findByText("Nenhum andamento cadastrado.")).toBeVisible()
  ;["Prazos", "Tarefas", "Perícias"].forEach((title) => {
    expect(screen.getByRole("heading", { name: title })).toBeVisible()
    expect(screen.getByRole("button", { name: title })).toBeVisible()
  })
})

test("reveals older timeline items on demand and keeps actions as links", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWithSixTimelineItems)))
  render(<LegalCaseShowApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: /Mostrar mais/ }))

  expect(screen.getByText("Andamento antigo")).toBeVisible()
  expect(screen.getByRole("link", { name: "Novo andamento" })).toHaveAttribute("href", "/process_movements/new?process_id=1")
})

test("shows an error and retry action when the snapshot fails", async () => {
  vi.stubGlobal("fetch", vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível carregar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByRole("heading", { name: "Cliente Aurora" })).toBeVisible()
})

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

test("shows a sync error and re-enables the button when the request fails", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce({ ok: false, json: async () => ({ error: "Serviço indisponível." }) }))
  render(<LegalCaseShowApp />)

  const button = await screen.findByRole("button", { name: "Atualizar andamentos" })
  await userEvent.setup().click(button)

  expect(await screen.findByRole("alert")).toHaveTextContent("Serviço indisponível.")
  expect(button).toBeEnabled()
})
