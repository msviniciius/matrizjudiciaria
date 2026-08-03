import "@testing-library/jest-dom/vitest"
import { readFileSync } from "node:fs"
import { fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { LegalCaseShowApp } from "./LegalCaseShowApp"

const timelineItem = (id: number, title: string, overrides = {}) => ({
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
  exam_summary: null,
  ...overrides
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
    outcome_date: null,
    outcome_date_label: "Não informada",
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
  intelligence: {
    status: "attention",
    summary: "Processo PROC-001 de Cliente Aurora está em análise com prazo próximo.",
    suggested_action: {
      title: "Analisar publicação mais recente",
      description: "Existem publicações ainda não lidas vinculadas ao processo.",
      priority: "high"
    },
    attention_points: [
      { title: "Publicações não lidas", description: "1 publicação aguardando leitura.", severity: "attention" },
      { title: "Prazo próximo", description: "1 prazo próximo.", severity: "attention" }
    ],
    metrics: {
      timeline_events_count: 3,
      pending_deadlines_count: 1,
      overdue_deadlines_count: 0,
      pending_tasks_count: 1,
      unread_publications_count: 1,
      latest_movement_label: "30/07/2026",
      next_deadline_label: "31/07/2026"
    }
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
    ai_analysis: { path: "/legal_cases/1/ai_analysis", method: "post" },
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

test("renders the deterministic process intelligence panel", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Inteligência do processo" })).toBeVisible()
  expect(screen.getByText("Processo PROC-001 de Cliente Aurora está em análise com prazo próximo.")).toBeVisible()
  expect(screen.getByRole("heading", { name: "Analisar publicação mais recente" })).toBeVisible()
  expect(screen.getByText("Publicações não lidas")).toBeVisible()
  expect(screen.getByText("1 publicação aguardando leitura.")).toBeVisible()
  expect(screen.getByText("Publicações não lidas").closest("article")).toHaveClass("react-legal-case-show__intelligence-point")
  expect(screen.getByText("Eventos na timeline").nextElementSibling).toHaveTextContent("3")
  expect(screen.getByText("Publicações pendentes").nextElementSibling).toHaveTextContent("1")
})

test("generates and displays an external ai analysis", async () => {
  const user = userEvent.setup()
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce({
      ok: true,
      status: 201,
      json: async () => ({
        analysis: {
          summary: "Resumo gerado pelo Gemini.",
          risks: ["Prazo recursal possível"],
          suggested_action: "Revisar publicação e confirmar prazo.",
          confidence: "medium",
          notes: "Sugestão gerada por IA. Revise antes de agir.",
          created_at_label: "03/08/2026 19:40"
        }
      })
    })
  vi.stubGlobal("fetch", fetchMock)
  render(<LegalCaseShowApp />)

  await screen.findByRole("heading", { name: "Inteligência do processo" })
  await user.click(screen.getByRole("button", { name: "Gerar análise com IA" }))

  expect(await screen.findByRole("heading", { name: "Análise com IA" })).toBeVisible()
  expect(screen.getByText("Resumo gerado pelo Gemini.")).toBeVisible()
  expect(screen.getByText("Prazo recursal possível")).toBeVisible()
  expect(screen.getByText("Revisar publicação e confirmar prazo.")).toBeVisible()
  expect(fetchMock).toHaveBeenLastCalledWith("/legal_cases/1/ai_analysis", expect.objectContaining({ method: "POST" }))
})

test("formats the claim value as Brazilian currency in the case data panel", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    case: { ...alertedSnapshot.case, claim_value: "1000.0" }
  })))
  render(<LegalCaseShowApp />)

  expect(await screen.findByText("Valor da causa")).toBeVisible()
  expect(screen.getByText("Valor da causa").nextElementSibling).toHaveTextContent("R$ 1.000,00")
})

test("describes an empty timeline and exposes each operational section through a heading toggle", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith([]))))
  render(<LegalCaseShowApp />)

  expect(await screen.findByText("Nenhum andamento cadastrado.")).toBeVisible()
  ;["Prazos", "Tarefas", "Perícias"].forEach((title) => {
    expect(screen.getByRole("heading", { name: title })).toBeVisible()
    expect(screen.getByRole("button", { name: title })).toBeVisible()
  })
  expect(screen.getByTestId("legal-case-show-prazos")).toHaveAttribute("aria-controls", "legal-case-show-prazos")
})

test("groups timeline movements by date in a vertical tree", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith([
    timelineItem(1, "Intimação publicada", { occurred_at: "2026-08-03", occurred_at_label: "03/08/2026" }),
    timelineItem(2, "Disponibilizado no DJE", { occurred_at: "2026-08-03", occurred_at_label: "03/08/2026" }),
    timelineItem(3, "Enviado ao diário", { occurred_at: "2026-08-02", occurred_at_label: "02/08/2026" })
  ]))))
  render(<LegalCaseShowApp />)

  const latestGroup = await screen.findByRole("group", { name: "03/08/2026" })
  const previousGroup = screen.getByRole("group", { name: "02/08/2026" })

  expect(latestGroup).toHaveClass("react-legal-case-show__timeline-group")
  expect(within(latestGroup).getByText("Intimação publicada")).toBeVisible()
  expect(within(latestGroup).getByText("Disponibilizado no DJE")).toBeVisible()
  expect(within(previousGroup).getByText("Enviado ao diário")).toBeVisible()
})

test("shows an empty financial panel and opens the contract setup action", async () => {
  const refreshListener = vi.fn()
  document.addEventListener("custom-select:refresh", refreshListener)
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    financial_contract: null,
    installments: [],
    actions: {
      ...alertedSnapshot.actions,
      financial_contract: { path: "/legal_cases/1/financial_contract", method: "post" }
    }
  })))
  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Honorários do processo" })).toBeVisible()
  expect(screen.getByText("Nenhum contrato financeiro configurado.")).toBeVisible()
  await userEvent.setup().click(screen.getByRole("button", { name: "Definir honorários" }))
  expect(screen.getByRole("dialog", { name: "Definir honorários e condições de pagamento" })).toBeVisible()
  expect(refreshListener).toHaveBeenCalledTimes(1)

  await userEvent.setup().click(screen.getByLabelText("Adicionar percentual de honorários"))
  expect(screen.getByLabelText("Base de cálculo")).toBeVisible()
  expect(refreshListener).toHaveBeenCalledTimes(2)

  document.removeEventListener("custom-select:refresh", refreshListener)
})

test("opens a populated financial contract with its existing editable installment schedule", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    financial_contract: {
      id: 1,
      fixed_amount: "1200.0",
      fixed_amount_label: "R$ 1.200,00",
      includes_percentage: false,
      percentage: null,
      percentage_basis: null,
      percentage_basis_label: null,
      percentage_base_amount: null,
      percentage_base_amount_label: "R$ 0,00",
      client_received_amount: null,
      client_received_amount_label: "R$ 0,00",
      installment_count: 2,
      first_due_date: "2026-11-12",
      total_amount: "1200.0",
      total_amount_label: "R$ 1.200,00",
      contract_document: null
    },
    installments: [
      { id: 11, number: 1, amount: "500.0", amount_label: "R$ 500,00", due_date: "2026-11-12", due_date_label: "12/11/2026", status: "pending", status_label: "Pendente", payment_recorded: false },
      { id: 12, number: 2, amount: "700.0", amount_label: "R$ 700,00", due_date: "2026-12-18", due_date_label: "18/12/2026", status: "pending", status_label: "Pendente", payment_recorded: false }
    ],
    actions: {
      ...alertedSnapshot.actions,
      financial_contract: { path: "/legal_cases/1/financial_contract", method: "patch" }
    }
  })))
  render(<LegalCaseShowApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Editar honorários" }))

  expect(screen.getByLabelText("Primeiro vencimento")).toHaveValue("2026-11-12")
  expect(screen.getByLabelText("Valor da 1ª parcela")).toHaveValue(500)
  expect(screen.getByLabelText("Vencimento da 2ª parcela")).toHaveValue("2026-12-18")
})

test("submits manually edited installment values and due dates", async () => {
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse({
      ...alertedSnapshot,
      financial_contract: null,
      installments: [],
      actions: {
        ...alertedSnapshot.actions,
        financial_contract: { path: "/legal_cases/1/financial_contract", method: "post" }
      }
    }))
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
  vi.stubGlobal("fetch", fetchMock)
  const user = userEvent.setup()
  render(<LegalCaseShowApp />)

  await user.click(await screen.findByRole("button", { name: "Definir honorários" }))
  await user.type(screen.getByLabelText("Valor fixo dos honorários"), "1200")
  await user.selectOptions(screen.getByLabelText("Quantidade de parcelas"), "2")
  fireEvent.change(screen.getByLabelText("Primeiro vencimento"), { target: { value: "2026-08-10" } })
  fireEvent.change(screen.getByLabelText("Valor da 1ª parcela"), { target: { value: "500.00" } })
  fireEvent.change(screen.getByLabelText("Valor da 2ª parcela"), { target: { value: "700.00" } })
  fireEvent.change(screen.getByLabelText("Vencimento da 2ª parcela"), { target: { value: "2026-10-20" } })
  await user.click(screen.getByRole("button", { name: "Salvar contrato" }))

  const submitted = fetchMock.mock.calls[1][1]?.body as FormData
  expect(submitted.getAll("financial_contract[installments][][amount]")).toEqual([ "500.00", "700.00" ])
  expect(submitted.getAll("financial_contract[installments][][due_date]")).toEqual([ "2026-08-10", "2026-10-20" ])
})

test("masks the fixed fee as Brazilian currency and submits a decimal value", async () => {
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse({
      ...alertedSnapshot,
      financial_contract: null,
      installments: [],
      actions: {
        ...alertedSnapshot.actions,
        financial_contract: { path: "/legal_cases/1/financial_contract", method: "post" }
      }
    }))
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
  vi.stubGlobal("fetch", fetchMock)
  const user = userEvent.setup()
  render(<LegalCaseShowApp />)

  await user.click(await screen.findByRole("button", { name: "Definir honorários" }))
  await user.type(screen.getByLabelText("Valor fixo dos honorários"), "120000")

  expect(screen.getByLabelText("Valor fixo dos honorários")).toHaveValue("1.200,00")

  await user.click(screen.getByRole("button", { name: "Salvar contrato" }))

  const submitted = fetchMock.mock.calls[1][1]?.body as FormData
  expect(submitted.get("financial_contract[fixed_amount]")).toBe("1200.00")
})

test("shows a styled file picker with the selected contract document name", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    financial_contract: null,
    installments: [],
    actions: {
      ...alertedSnapshot.actions,
      financial_contract: { path: "/legal_cases/1/financial_contract", method: "post" }
    }
  })))
  const user = userEvent.setup()
  render(<LegalCaseShowApp />)

  await user.click(await screen.findByRole("button", { name: "Definir honorários" }))

  const picker = screen.getByLabelText("Contrato assinado")
  expect(screen.getByText("Selecionar arquivo")).toBeVisible()
  expect(screen.getByText("Nenhum arquivo selecionado")).toBeVisible()

  await user.upload(picker, new File(["contrato"], "contrato-assinado.pdf", { type: "application/pdf" }))

  expect(screen.getByText("contrato-assinado.pdf")).toBeVisible()
})

test("lets an administrator register the outcome from a contextual modal", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_date_label: "30/07/2026",
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

test("renders the localized outcome date and confirmation details in the outcome summary", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse({
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_date_label: "30/07/2026",
      outcome_confirmed_at: "2026-07-31T12:00:00Z",
      outcome_confirmed_at_label: "31/07/2026",
      outcome_confirmed_by_name: "Marina"
    }
  })))

  render(<LegalCaseShowApp />)

  expect(await screen.findByRole("heading", { name: "Desfecho do processo" })).toBeVisible()
  expect(screen.getByText("Data do desfecho").nextElementSibling).toHaveTextContent("30/07/2026")
  expect(screen.getByText("Registrado em").nextElementSibling).toHaveTextContent("31/07/2026")
  expect(screen.getByText("Registrado por").nextElementSibling).toHaveTextContent("Marina")
})

test("keeps the modal open and exposes a server error when recording fails", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce({ ok: false, json: async () => ({ errors: { outcome: ["não pode ficar em branco"] } }) }))
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  await user.click(await screen.findByRole("button", { name: "Registrar desfecho" }))
  fireEvent.change(screen.getByLabelText("Data do desfecho"), { target: { value: "2026-07-30" } })
  await user.click(screen.getByRole("button", { name: "Confirmar desfecho" }))

  expect(await screen.findByRole("alert")).toHaveTextContent("não pode ficar em branco")
  expect(screen.getByRole("dialog", { name: "Registrar desfecho" })).toBeVisible()
})

test("disables outcome submission controls while the request is pending", async () => {
  let resolveOutcome!: (response: unknown) => void
  const pendingOutcome = new Promise<unknown>((resolve) => { resolveOutcome = resolve })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockReturnValueOnce(pendingOutcome))
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  await user.click(await screen.findByRole("button", { name: "Registrar desfecho" }))
  fireEvent.change(screen.getByLabelText("Data do desfecho"), { target: { value: "2026-07-30" } })
  await user.click(screen.getByRole("button", { name: "Confirmar desfecho" }))

  expect(screen.getByRole("button", { name: "Registrando…" })).toBeDisabled()
  expect(screen.getByRole("button", { name: "Cancelar" })).toBeDisabled()
  expect(screen.getByLabelText("Resultado")).toBeDisabled()
  expect(screen.getByLabelText("Data do desfecho")).toBeDisabled()

  resolveOutcome(okResponse(alertedSnapshot))
  await screen.findByRole("status")
})

test("restores focus to the outcome action after closing the modal", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(alertedSnapshot)))
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()
  const trigger = await screen.findByRole("button", { name: "Registrar desfecho" })

  await user.click(trigger)
  expect(screen.getByRole("dialog", { name: "Registrar desfecho" })).toBeVisible()
  expect(screen.getByTestId("legal-case-sync-content")).toHaveAttribute("inert")

  await user.click(screen.getByRole("button", { name: "Cancelar" }))

  await waitFor(() => expect(screen.queryByRole("dialog", { name: "Registrar desfecho" })).not.toBeInTheDocument())
  expect(screen.getByTestId("legal-case-sync-content")).not.toHaveAttribute("inert")
  expect(trigger).toHaveFocus()
})

test("saves an outcome with the snapshot returned by the endpoint", async () => {
  const refreshedSnapshot = {
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_date_label: "30/07/2026",
      outcome_confirmed_at: "2026-07-31T12:00:00Z",
      outcome_confirmed_at_label: "31/07/2026",
      outcome_confirmed_by_name: "Marina"
    }
  }
  const fetchMock = vi.fn()
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
  expect(fetchMock).toHaveBeenCalledTimes(2)
})

test("keeps a recorded outcome successful when a later snapshot request fails", async () => {
  const recordedSnapshot = {
    ...alertedSnapshot,
    case: {
      ...alertedSnapshot.case,
      outcome: "won",
      outcome_label: "Ganho",
      outcome_date: "2026-07-30",
      outcome_date_label: "30/07/2026",
      outcome_confirmed_at: "2026-07-31T12:00:00Z",
      outcome_confirmed_at_label: "31/07/2026",
      outcome_confirmed_by_name: "Marina"
    }
  }
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(alertedSnapshot))
    .mockResolvedValueOnce(okResponse(recordedSnapshot))
    .mockRejectedValueOnce(new Error("snapshot request failed"))
  vi.stubGlobal("fetch", fetchMock)
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  await user.click(await screen.findByRole("button", { name: "Registrar desfecho" }))
  await user.selectOptions(screen.getByLabelText("Resultado"), "won")
  fireEvent.change(screen.getByLabelText("Data do desfecho"), { target: { value: "2026-07-30" } })
  await user.click(screen.getByRole("button", { name: "Confirmar desfecho" }))

  expect(await screen.findByRole("status")).toHaveTextContent("Desfecho do processo registrado com sucesso.")
  expect(screen.getByText("Desfecho: Ganho")).toBeVisible()
  expect(screen.queryByRole("dialog", { name: "Registrar desfecho" })).not.toBeInTheDocument()
  expect(screen.queryByRole("alert")).not.toBeInTheDocument()
  expect(fetchMock).toHaveBeenCalledTimes(2)
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

test("maximizes and minimizes older timeline items on demand while keeping actions as links", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWithSixTimelineItems)))
  render(<LegalCaseShowApp />)
  const user = userEvent.setup()

  expect(screen.queryByText("Andamento antigo")).not.toBeInTheDocument()
  const toggle = await screen.findByTestId("legal-case-show-timeline-more")
  expect(toggle.closest("h2")).not.toBeNull()
  expect(toggle).toHaveTextContent("Timeline+")
  expect(toggle).toHaveAttribute("aria-expanded", "false")

  await user.click(toggle)

  expect(screen.getByText("Andamento antigo")).toBeVisible()
  expect(screen.getByTestId("legal-case-show-timeline-more")).toHaveTextContent("Timeline−")
  expect(screen.getByTestId("legal-case-show-timeline-more")).toHaveAttribute("aria-expanded", "true")

  await user.click(screen.getByTestId("legal-case-show-timeline-more"))

  expect(screen.queryByText("Andamento antigo")).not.toBeInTheDocument()
  expect(screen.getByTestId("legal-case-show-timeline-more")).toHaveTextContent("Timeline+")
  expect(screen.getByTestId("legal-case-show-timeline-more")).toHaveAttribute("aria-expanded", "false")
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
