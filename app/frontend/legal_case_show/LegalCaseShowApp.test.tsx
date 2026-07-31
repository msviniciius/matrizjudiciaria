import "@testing-library/jest-dom/vitest"
import { readFileSync } from "node:fs"
import { fireEvent, render, screen, waitFor } from "@testing-library/react"
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
    tem_pericia: true,
    outcome: "undefined",
    outcome_label: "Não definido",
    outcome_confirmed_at: null,
    outcome_confirmed_at_label: "Ainda não registrado",
    outcome_notes: null,
    outcome_confirmed_by_name: null
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
    sync: { path: "/legal_cases/1/sync", method: "post" },
    record_outcome: { path: "/legal_cases/1/outcome", method: "patch" }
  },
  permissions: { can_record_outcome: true }
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
  document.querySelectorAll('[data-legal-case-sync-background]').forEach((element) => element.remove())
  window.history.replaceState({}, "", "/")
})

function addSyncBackgroundRegion() {
  const region = document.createElement("nav")
  region.dataset.legalCaseSyncBackground = ""
  region.innerHTML = '<a href="/legal_cases">Processos</a>'
  document.body.append(region)
  return region
}

test("renders the command center and opens an alerted deadline section", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Cliente Aurora" })).toBeVisible()
  expect(screen.getByRole("region", { name: "Central de comando" })).toBeVisible()
  expect(screen.queryByRole("main")).not.toBeInTheDocument()
  expect(screen.getByRole("button", { name: /Prazos/ })).toHaveAttribute("aria-expanded", "true")
  expect(screen.getByRole("link", { name: "Editar processo" })).toBeVisible()
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

test("lets an administrator register the outcome from a contextual modal", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_notes: "Sentença favorável.",
      outcome_confirmed_at_label: "30/07/2026"
    }
  })))
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  await user.click(await screen.findByRole("button", { name: "Registrar desfecho" }))

  const dialog = screen.getByRole("dialog", { name: "Registrar desfecho" })
  expect(dialog).toBeVisible()
  expect(screen.getByLabelText("Resultado")).toHaveValue("won")
  expect(screen.getByLabelText("Data do desfecho")).toHaveValue("2026-07-30")
  expect(screen.getByLabelText("Observação")).toHaveValue("Sentença favorável.")
})

test("saves an outcome and reloads the process snapshot", async () => {
  const refreshedSnapshot = {
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_confirmed_at: "2026-07-31T12:00:00Z",
      outcome_confirmed_at_label: "31/07/2026",
      outcome_confirmed_by_name: "Marina"
    }
  }
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce(okResponse(refreshedSnapshot))
  vi.stubGlobal("fetch", fetchMock)
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  await user.click(await screen.findByRole("button", { name: "Registrar desfecho" }))
  await user.selectOptions(screen.getByLabelText("Resultado"), "won")
  fireEvent.change(screen.getByLabelText("Data do desfecho"), { target: { value: "2026-07-30" } })
  await user.click(screen.getByRole("button", { name: "Confirmar desfecho" }))

  expect(await screen.findByRole("status")).toHaveTextContent("Desfecho do processo registrado com sucesso.")
  expect(screen.getByText("Desfecho: Ganho")).toBeVisible()
  expect(fetchMock).toHaveBeenNthCalledWith(2, "/legal_cases/1/outcome", expect.objectContaining({
    method: "PATCH",
    body: JSON.stringify({ legal_case: { outcome: "won", outcome_date: "2026-07-30", outcome_notes: "" } })
  }))
})

test("does not expose outcome controls without administrator permission", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    actions: { ...alertedSnapshot.actions, record_outcome: null },
    permissions: { can_record_outcome: false }
  })))
  render(<LegalCaseShowApp />)

  await screen.findByRole("heading", { name: "Cliente Aurora" })
  expect(screen.queryByRole("button", { name: "Registrar desfecho" })).not.toBeInTheDocument()
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
  expect(screen.getByRole("status", { name: /buscando andamentos/i })).toBeVisible()
  expect(screen.getByTestId("legal-case-sync-overlay")).toHaveAttribute("aria-busy", "true")
  expect(screen.getByTestId("legal-case-sync-overlay")).toHaveTextContent("Buscando andamentos…")
  expect(screen.getByTestId("legal-case-sync-content")).toHaveAttribute("inert")

  resolveSync(okResponse({ message: "1 andamento novo importado." }))
  await waitFor(() => expect(screen.queryByTestId("legal-case-sync-overlay")).not.toBeInTheDocument())
  expect(screen.getByTestId("legal-case-sync-content")).not.toHaveAttribute("inert")
  expect(screen.getByRole("status")).toHaveTextContent("1 andamento novo importado.")
  expect(screen.getByText("Andamento importado")).toBeVisible()
  expect(fetchMock).toHaveBeenNthCalledWith(2, "/legal_cases/1/sync", expect.objectContaining({
    method: "POST", headers: expect.objectContaining({ "X-CSRF-Token": "csrf-detail-token" })
  }))
})

test("inerts external shell regions only while synchronization is pending", async () => {
  const shellRegion = addSyncBackgroundRegion()
  let resolveSync!: (response: unknown) => void
  const pendingSync = new Promise<unknown>((resolve) => { resolveSync = resolve })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockReturnValueOnce(pendingSync)
    .mockResolvedValueOnce(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Atualizar andamentos" }))

  expect(shellRegion).toHaveAttribute("inert")
  expect(screen.getByTestId("legal-case-sync-overlay")).not.toHaveAttribute("inert")

  resolveSync(okResponse({ message: "Andamentos atualizados." }))
  await waitFor(() => expect(shellRegion).not.toHaveAttribute("inert"))
})

test("removes inert from external shell regions after a sync error and on unmount", async () => {
  const shellRegion = addSyncBackgroundRegion()
  let rejectSync!: (error: Error) => void
  const pendingSync = new Promise<unknown>((_resolve, reject) => { rejectSync = reject })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockReturnValueOnce(pendingSync))
  const { unmount } = render(<LegalCaseShowApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Atualizar andamentos" }))
  expect(shellRegion).toHaveAttribute("inert")

  rejectSync(new Error("Serviço indisponível."))
  await waitFor(() => expect(shellRegion).not.toHaveAttribute("inert"))

  let resolveSecondSync!: (response: unknown) => void
  const secondPendingSync = new Promise<unknown>((resolve) => { resolveSecondSync = resolve })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockReturnValueOnce(secondPendingSync))
  unmount()
  const secondRender = render(<LegalCaseShowApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Atualizar andamentos" }))
  expect(shellRegion).toHaveAttribute("inert")

  secondRender.unmount()
  expect(shellRegion).not.toHaveAttribute("inert")
  resolveSecondSync(okResponse({ message: "Ignorado após desmontagem." }))
})

test("removes the native synchronization control from the legal case view", () => {
  const view = readFileSync("app/views/legal_cases/show.html.erb", "utf8")

  expect(view).not.toContain("sync_legal_case_path")
  expect(view).not.toContain("button_to")
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

test("renders a no-movement sync response as an alert", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce(okResponse({ message: "Nenhum andamento encontrado para este processo no CNJ.", level: "alert" }))
    .mockResolvedValueOnce(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Atualizar andamentos" }))

  expect(await screen.findByRole("alert")).toHaveTextContent("Nenhum andamento encontrado para este processo no CNJ.")
  expect(screen.queryByRole("status", { name: /nenhum andamento encontrado/i })).not.toBeInTheDocument()
})
