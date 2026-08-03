/// <reference path="../vite-env.d.ts" />

import { useEffect, useRef, useState } from "react"
import "./legalCaseShow.css"

type TimelineItem = {
  id: number
  source: string
  source_label: string | null
  title: string
  description: string | null
  occurred_at: string | null
  occurred_at_label: string
  movement_type: string | null
  origin: string | null
  highlight: boolean
  nature: string | null
  administrative_situation: string | null
  exam_summary: string | null
}

type Deadline = {
  id: number
  title: string
  due_date: string | null
  due_date_label: string
  status: string
  status_label: string
  priority: string
  priority_label: string
  deadline_type: string
  deadline_type_label: string
  responsible_name: string
  delay_reason: string
  path: string
}

type Task = {
  id: number
  title: string
  description: string | null
  due_date: string | null
  due_date_label: string
  status: string
  status_label: string
  priority: string
  priority_label: string
  responsible_name: string
  path: string
}

type Exam = {
  id: number
  nature: string
  nature_label: string
  scope: string
  scope_label: string
  scheduled_at: string | null
  scheduled_label: string
  status: string
  status_label: string
  location: string
  expert_name: string
  notes: string | null
  active: boolean
  path: string
}

type FinancialContract = {
  id: number
  fixed_amount: string | number
  fixed_amount_label: string
  includes_percentage: boolean
  percentage: string | number | null
  percentage_basis: "claim_value" | "client_received" | null
  percentage_basis_label: string | null
  percentage_base_amount: string | number | null
  percentage_base_amount_label: string
  client_received_amount: string | number | null
  client_received_amount_label: string
  installment_count: number
  first_due_date: string | null
  total_amount: string | number
  total_amount_label: string
  contract_document: { name: string; url: string } | null
}

type FinancialInstallment = {
  id: number
  number: number
  amount: string | number
  amount_label: string
  due_date: string | null
  due_date_label: string
  status: "pending" | "paid"
  status_label: string
  payment_recorded: boolean
  payment: {
    amount_label: string
    paid_at_label: string
    payment_method_label: string
    recorded_by_name: string | null
    proof: string | null
  } | null
  payment_action: string | null
}

type AiAnalysis = {
  summary: string
  risks: string[]
  suggested_action: string
  confidence: "low" | "medium" | "high"
  notes: string | null
  created_at_label: string | null
}

type Snapshot = {
  case: {
    id: number
    internal_number: string
    external_number: string | null
    client_name: string
    phase_label: string
    status_label: string
    priority_label: string
    responsible_name: string
    legal_area_name: string
    process_type_name: string
    court_name: string
    district_name: string
    claim_value: string | number | null
    opposing_party: string
    tem_pericia: boolean
    outcome: Outcome
    outcome_label: string
    outcome_date: string | null
    outcome_date_label: string
    outcome_confirmed_at: string | null
    outcome_confirmed_at_label: string
    outcome_notes: string | null
    outcome_confirmed_by_name: string | null
  }
  alerts: {
    deadline_near: boolean
    deadline_overdue: boolean
    exam_pending: boolean
    next_action_warning: boolean
    stale_last_movement: boolean
    health_status: string
    has_new_imported_events: boolean
  }
  intelligence: {
    status: "stable" | "attention" | "critical"
    summary: string
    suggested_action: {
      title: string
      description: string
      priority: "low" | "medium" | "high"
    }
    attention_points: Array<{
      title: string
      description: string
      severity: "attention" | "critical"
    }>
    metrics: {
      timeline_events_count: number
      pending_deadlines_count: number
      overdue_deadlines_count: number
      pending_tasks_count: number
      unread_publications_count: number
      latest_movement_label: string
      next_deadline_label: string
    }
  }
  next_action: {
    description: string
    deadline_on: string | null
    deadline_label: string
    last_movement_at: string | null
    last_movement_label: string
  }
  timeline: TimelineItem[]
  deadlines: Deadline[]
  tasks: Task[]
  exams: Exam[]
  financial_contract?: FinancialContract | null
  installments?: FinancialInstallment[]
  actions: {
    index: string
    edit: string
    pdf: string
    calendar: string
    new_movement: string
    new_deadline: string
    new_task: string
    new_exam: string | null
    sync: { path: string; method: string } | null
    ai_analysis: { path: string; method: string } | null
    record_outcome: { path: string; method: string } | null
    financial_contract?: { path: string; method: string }
  }
  permissions: { can_record_outcome: boolean; can_manage_financial_contract?: boolean }
}

type Outcome = "undefined" | "won" | "lost" | "settled" | "partially_won"
type TimelineGroup = {
  dateLabel: string
  items: TimelineItem[]
}

const outcomeOptions: Array<{ value: Outcome; label: string }> = [
  { value: "undefined", label: "Sem definição" },
  { value: "won", label: "Ganho" },
  { value: "lost", label: "Perdido" },
  { value: "settled", label: "Acordo" },
  { value: "partially_won", label: "Parcialmente ganho" }
]

function fetchSnapshot(): Promise<Snapshot> {
  return fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

function groupTimelineByDate(items: TimelineItem[]): TimelineGroup[] {
  return items.reduce<TimelineGroup[]>((groups, item) => {
    const dateLabel = item.occurred_at_label || "Sem data"
    const currentGroup = groups[groups.length - 1]

    if (currentGroup?.dateLabel === dateLabel) {
      currentGroup.items.push(item)
    } else {
      groups.push({ dateLabel, items: [item] })
    }

    return groups
  }, [])
}

export function LegalCaseShowApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [showAllTimeline, setShowAllTimeline] = useState(false)
  const [syncPending, setSyncPending] = useState(false)
  const [syncError, setSyncError] = useState<string | null>(null)
  const [syncMessage, setSyncMessage] = useState<string | null>(null)
  const [outcomeModalOpen, setOutcomeModalOpen] = useState(false)
  const [outcomePending, setOutcomePending] = useState(false)
  const [outcomeError, setOutcomeError] = useState<string | null>(null)
  const [outcomeMessage, setOutcomeMessage] = useState<string | null>(null)
  const [financialModalOpen, setFinancialModalOpen] = useState(false)
  const [financialPending, setFinancialPending] = useState(false)
  const [financialError, setFinancialError] = useState<string | null>(null)
  const [financialMessage, setFinancialMessage] = useState<string | null>(null)
  const [paymentInstallment, setPaymentInstallment] = useState<FinancialInstallment | null>(null)
  const [paymentPending, setPaymentPending] = useState(false)
  const [paymentError, setPaymentError] = useState<string | null>(null)
  const [aiAnalysis, setAiAnalysis] = useState<AiAnalysis | null>(null)
  const [aiPending, setAiPending] = useState(false)
  const [aiError, setAiError] = useState<string | null>(null)
  const outcomeButtonRef = useRef<HTMLButtonElement>(null)
  const restoreOutcomeButtonFocus = useRef(false)

  const loadSnapshot = async () => {
    setError(null)
    setIsLoading(true)
    try {
      const nextSnapshot = await fetchSnapshot()
      setSnapshot(nextSnapshot)
      setShowAllTimeline(false)
    } catch {
      setError("Não foi possível carregar os dados do processo. Tente novamente.")
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadSnapshot()
  }, [])

  const interactionLocked = syncPending || outcomeModalOpen || financialModalOpen || Boolean(paymentInstallment)

  useEffect(() => {
    if (!interactionLocked) return

    const backgroundRegions = Array.from(document.querySelectorAll<HTMLElement>("[data-legal-case-sync-background]"))
      .filter((element) => !element.hasAttribute("inert"))

    backgroundRegions.forEach((element) => element.setAttribute("inert", ""))

    return () => {
      backgroundRegions.forEach((element) => element.removeAttribute("inert"))
    }
  }, [interactionLocked])

  useEffect(() => {
    if (outcomeModalOpen || !restoreOutcomeButtonFocus.current) return

    restoreOutcomeButtonFocus.current = false
    outcomeButtonRef.current?.focus()
  }, [outcomeModalOpen])

  if (isLoading && !snapshot) {
    return <section className="react-legal-case-show react-legal-case-show--loading" aria-label="Central de comando"><p role="status">Carregando processo…</p></section>
  }

  if (error && !snapshot) {
    return <section className="react-legal-case-show react-legal-case-show--loading" aria-label="Central de comando"><section className="react-legal-case-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section></section>
  }

  if (!snapshot) return null

  const syncCase = async (action: NonNullable<Snapshot["actions"]["sync"]>) => {
    setSyncPending(true)
    setSyncError(null)
    setSyncMessage(null)

    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
      const response = await fetch(action.path, {
        method: action.method.toUpperCase(),
        headers: { Accept: "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) }
      })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Não foi possível sincronizar os andamentos.")
      await loadSnapshot()
      if (body.level === "alert") {
        setSyncError(body.message)
      } else {
        setSyncMessage(body.message)
      }
    } catch (syncFailure) {
      setSyncError(syncFailure instanceof Error ? syncFailure.message : "Não foi possível sincronizar os andamentos.")
    } finally {
      setSyncPending(false)
    }
  }

  const openOutcomeModal = () => {
    setOutcomeError(null)
    setOutcomeMessage(null)
    setOutcomeModalOpen(true)
  }

  const closeOutcomeModal = () => {
    if (outcomePending) return

    restoreOutcomeButtonFocus.current = true
    setOutcomeModalOpen(false)
  }

  const recordOutcome = async (payload: { outcome: Outcome; outcomeDate: string; outcomeNotes: string }) => {
    const action = snapshot.actions.record_outcome
    if (!action) return

    setOutcomePending(true)
    setOutcomeError(null)
    setOutcomeMessage(null)

    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
      const response = await fetch(action.path, {
        method: action.method.toUpperCase(),
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
        },
        body: JSON.stringify({ legal_case: {
          outcome: payload.outcome,
          outcome_date: payload.outcomeDate,
          outcome_notes: payload.outcomeNotes
        } })
      })
      const body = await response.json().catch(() => ({})) as Snapshot & { errors?: Record<string, string[] | string>; error?: string }
      if (!response.ok) throw new Error(outcomeErrorMessage(body))

      setSnapshot(body)
      restoreOutcomeButtonFocus.current = true
      setOutcomeModalOpen(false)
      setOutcomeMessage("Desfecho do processo registrado com sucesso.")
    } catch (outcomeFailure) {
      setOutcomeError(outcomeFailure instanceof Error ? outcomeFailure.message : "Não foi possível registrar o desfecho.")
    } finally {
      setOutcomePending(false)
    }
  }

  const saveFinancialContract = async (formData: FormData) => {
    const action = snapshot.actions.financial_contract
    if (!action) return

    setFinancialPending(true)
    setFinancialError(null)
    setFinancialMessage(null)

    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
      const response = await fetch(action.path, {
        method: action.method.toUpperCase(),
        headers: { Accept: "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) },
        body: formData
      })
      const body = await response.json().catch(() => ({})) as Snapshot & { errors?: Record<string, string[] | string>; error?: string }
      if (!response.ok) throw new Error(outcomeErrorMessage(body))

      setSnapshot(body)
      setFinancialModalOpen(false)
      setFinancialMessage("Contrato financeiro salvo com sucesso.")
    } catch (financialFailure) {
      setFinancialError(financialFailure instanceof Error ? financialFailure.message : "Não foi possível salvar o contrato financeiro.")
    } finally {
      setFinancialPending(false)
    }
  }

  const registerPayment = async (formData: FormData) => {
    if (!paymentInstallment?.payment_action) return

    setPaymentPending(true)
    setPaymentError(null)
    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
      const response = await fetch(paymentInstallment.payment_action, {
        method: "POST",
        headers: { Accept: "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) },
        body: formData
      })
      const body = await response.json().catch(() => ({})) as Snapshot & { error?: string }
      if (!response.ok) throw new Error(body.error || "Não foi possível registrar o recebimento.")

      setSnapshot(body)
      setPaymentInstallment(null)
    } catch (paymentFailure) {
      setPaymentError(paymentFailure instanceof Error ? paymentFailure.message : "Não foi possível registrar o recebimento.")
    } finally {
      setPaymentPending(false)
    }
  }

  const generateAiAnalysis = async () => {
    if (!snapshot.actions.ai_analysis) return

    setAiPending(true)
    setAiError(null)
    try {
      const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
      const response = await fetch(snapshot.actions.ai_analysis.path, {
        method: snapshot.actions.ai_analysis.method.toUpperCase(),
        headers: { Accept: "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) }
      })
      const body = await response.json().catch(() => ({})) as { analysis?: AiAnalysis; error?: string }
      if (!response.ok || !body.analysis) throw new Error(body.error || "Não foi possível gerar a análise com IA.")

      setAiAnalysis(body.analysis)
    } catch (generationError) {
      setAiError(generationError instanceof Error ? generationError.message : "Não foi possível gerar a análise com IA.")
    } finally {
      setAiPending(false)
    }
  }

  const timelineLimit = 5
  const visibleTimeline = showAllTimeline ? snapshot.timeline : snapshot.timeline.slice(0, timelineLimit)
  const timelineGroups = groupTimelineByDate(visibleTimeline)
  const remainingTimelineItems = snapshot.timeline.length - visibleTimeline.length
  const deadlineAlert = snapshot.alerts.deadline_near || snapshot.alerts.deadline_overdue

  return <section className="react-legal-case-show" aria-label="Central de comando">
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
    <div data-testid="legal-case-sync-content" inert={interactionLocked || undefined}>
    <header className="react-legal-case-show__header">
      <div>
        <p className="react-legal-case-show__client">Central de comando</p>
        <h1>{snapshot.case.client_name}</h1>
        <p className="react-legal-case-show__eyebrow">Processo {snapshot.case.internal_number}</p>
        <p className="react-legal-case-show__identifiers">{snapshot.case.external_number ? `CNJ: ${snapshot.case.external_number}` : "Sem número CNJ"}</p>
      </div>
      <div className="react-legal-case-show__header-actions"><div className="react-legal-case-show__actions">{snapshot.permissions.can_record_outcome && snapshot.actions.record_outcome && <button className="react-legal-case-show__actions-button" type="button" onClick={openOutcomeModal} ref={outcomeButtonRef}>Registrar desfecho</button>}<a href={snapshot.actions.edit}>Editar processo</a><a href={snapshot.actions.pdf} target="_blank" rel="noreferrer">Exportar PDF</a><a href={snapshot.actions.index}>Voltar</a></div><div className="react-legal-case-show__badges" aria-label="Situação do processo">
        <span className="react-legal-case-show__badge">{snapshot.case.phase_label}</span>
        <span className="react-legal-case-show__badge">{snapshot.case.status_label}</span>
        <span className="react-legal-case-show__badge react-legal-case-show__badge--priority">Prioridade {snapshot.case.priority_label}</span>
        {snapshot.case.outcome !== "undefined" && <span className="react-legal-case-show__badge react-legal-case-show__badge--outcome">Desfecho: {snapshot.case.outcome_label}</span>}
        <AlertSummary alerts={snapshot.alerts} />
      </div></div>
    </header>

    {error && <section className="react-legal-case-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section>}
    {isLoading && <p className="react-legal-case-show__refreshing" role="status">Atualizando processo…</p>}
    {syncError && <p className="react-legal-case-show__sync-notice react-legal-case-show__sync-notice--error" role="alert">{syncError}</p>}
    {syncMessage && <p className="react-legal-case-show__sync-notice" role="status">{syncMessage}</p>}
    {outcomeMessage && <p className="react-legal-case-show__outcome-notice" role="status">{outcomeMessage}</p>}
    {financialMessage && <p className="react-legal-case-show__financial-notice" role="status">{financialMessage}</p>}

    <div className="react-legal-case-show__layout">
    <div className="react-legal-case-show__main-column">
    <ProcessIntelligencePanel
      intelligence={snapshot.intelligence}
      analysis={aiAnalysis}
      actionAvailable={Boolean(snapshot.actions.ai_analysis)}
      pending={aiPending}
      error={aiError}
      onGenerate={generateAiAnalysis}
    />

    <section className="react-legal-case-show__next-action" aria-labelledby="next-action-heading">
      <h2 id="next-action-heading">Próxima providência</h2>
      <p>{snapshot.next_action.description}</p>
      <dl className="react-legal-case-show__metrics">
        <div><dt>Próximo prazo</dt><dd>{snapshot.next_action.deadline_label}</dd></div>
        <div><dt>Último andamento</dt><dd>{snapshot.next_action.last_movement_label}</dd></div>
      </dl>
      <nav className="react-legal-case-show__actions" aria-label="Ações do processo">
        <a href={snapshot.actions.new_movement}>Novo andamento</a>
        <a href={snapshot.actions.new_deadline}>Novo prazo</a>
        <a href={snapshot.actions.new_task}>Nova tarefa</a>
        {snapshot.actions.new_exam && <a href={snapshot.actions.new_exam}>Nova perícia</a>}
      </nav>
    </section>

    <FinancialPanel
      contract={snapshot.financial_contract || null}
      installments={snapshot.installments || []}
      onConfigure={() => {
        setFinancialError(null)
        setFinancialModalOpen(true)
      }}
      onRegisterPayment={(installment) => {
        setPaymentError(null)
        setPaymentInstallment(installment)
      }}
    />

    <section className="react-legal-case-show__timeline" aria-labelledby="timeline-heading">
      <h2 id="timeline-heading">
        {snapshot.timeline.length > timelineLimit ? <button type="button" data-testid="legal-case-show-timeline-more" aria-expanded={showAllTimeline} onClick={() => setShowAllTimeline((current) => !current)}><span>Timeline</span><span aria-hidden="true">{showAllTimeline ? "−" : "+"}</span></button> : "Timeline"}
      </h2>
      {timelineGroups.length ? <ol className="react-legal-case-show__timeline-tree">
        {timelineGroups.map((group) => <li className="react-legal-case-show__timeline-group" role="group" aria-label={group.dateLabel} key={group.dateLabel}>
          <div className="react-legal-case-show__timeline-date">
            <span className="react-legal-case-show__timeline-date-marker" aria-hidden="true" />
            <span className="react-legal-case-show__timeline-date-label">{group.dateLabel}</span>
          </div>
          <ol className="react-legal-case-show__timeline-events">
            {group.items.map((item) => <li className={item.highlight ? "react-legal-case-show__timeline-item react-legal-case-show__timeline-item--highlight" : "react-legal-case-show__timeline-item"} key={`${item.source}-${item.id}`}>
              <span className="react-legal-case-show__timeline-item-marker" aria-hidden="true" />
              <article className="react-legal-case-show__timeline-card">
                <p className="react-legal-case-show__timeline-meta">{item.source_label || item.source}</p>
                <h3>{item.title}</h3>
                {item.description && <p>{item.description}</p>}
                {item.movement_type && <p>{item.movement_type}</p>}
                {item.exam_summary && <p>Perícia: {item.exam_summary}</p>}
              </article>
            </li>)}
          </ol>
        </li>)}
      </ol> : <p>Nenhum andamento cadastrado.</p>}
    </section>

    <OperationalSection title="Prazos" hasAlert={deadlineAlert}>
      <CollectionEmpty items={snapshot.deadlines} message="Nenhum prazo cadastrado.">
        {snapshot.deadlines.map((deadline) => <article className="react-legal-case-show__operational-item" key={deadline.id}>
          <h3><a href={deadline.path}>{deadline.title}</a></h3>
          <p>{deadline.due_date_label} · {deadline.status_label} · Prioridade {deadline.priority_label}</p>
          <p>Responsável: {deadline.responsible_name}</p>
        </article>)}
      </CollectionEmpty>
    </OperationalSection>

    <OperationalSection title="Tarefas" hasAlert={snapshot.alerts.next_action_warning}>
      <CollectionEmpty items={snapshot.tasks} message="Nenhuma tarefa cadastrada.">
        {snapshot.tasks.map((task) => <article className="react-legal-case-show__operational-item" key={task.id}>
          <h3><a href={task.path}>{task.title}</a></h3>
          {task.description && <p>{task.description}</p>}
          <p>{task.due_date_label} · {task.status_label} · Prioridade {task.priority_label}</p>
          <p>Responsável: {task.responsible_name}</p>
        </article>)}
      </CollectionEmpty>
    </OperationalSection>

    <OperationalSection title="Perícias" hasAlert={snapshot.alerts.exam_pending}>
      <CollectionEmpty items={snapshot.exams} message="Nenhuma perícia cadastrada.">
        {snapshot.exams.map((exam) => <article className="react-legal-case-show__operational-item" key={exam.id}>
          <h3><a href={exam.path}>Perícia {exam.nature_label}</a></h3>
          <p>{exam.scope_label} · {exam.scheduled_label} · {exam.status_label}</p>
          <p>Local: {exam.location} · Perito: {exam.expert_name}</p>
          {exam.notes && <p>{exam.notes}</p>}
        </article>)}
      </CollectionEmpty>
    </OperationalSection>

    </div>
    <aside className="react-legal-case-show__rail" aria-label="Contexto do processo">
    <section className="react-legal-case-show__case-data" aria-labelledby="case-data-heading">
      <h2 id="case-data-heading">Dados do processo</h2>
      <dl>
        <div><dt>Responsável</dt><dd>{snapshot.case.responsible_name}</dd></div>
        <div><dt>Área do direito</dt><dd>{snapshot.case.legal_area_name}</dd></div>
        <div><dt>Tipo de processo</dt><dd>{snapshot.case.process_type_name}</dd></div>
        <div><dt>Órgão / Vara</dt><dd>{snapshot.case.court_name}</dd></div>
        <div><dt>Comarca</dt><dd>{snapshot.case.district_name}</dd></div>
        <div><dt>Valor da causa</dt><dd>{formatOptionalCurrency(snapshot.case.claim_value)}</dd></div>
        <div><dt>Parte contrária</dt><dd>{snapshot.case.opposing_party}</dd></div>
      </dl>
    </section>

    {snapshot.case.outcome !== "undefined" && <OutcomeSummary legalCase={snapshot.case} />}

    <nav className="react-legal-case-show__shortcuts" aria-label="Atalhos do processo">
      <a href={snapshot.actions.calendar}>Adicionar ao calendário</a>
      {snapshot.actions.sync && <SyncForm action={snapshot.actions.sync} onSync={syncCase} pending={syncPending} />}
    </nav>
    </aside>
    </div>
    </div>
    {outcomeModalOpen && snapshot.actions.record_outcome && <OutcomeModal
      legalCase={snapshot.case}
      pending={outcomePending}
      error={outcomeError}
      onClose={closeOutcomeModal}
      onSubmit={recordOutcome}
    />}
    {financialModalOpen && snapshot.actions.financial_contract && <FinancialContractModal
      legalCase={snapshot.case}
      contract={snapshot.financial_contract || null}
      installments={snapshot.installments || []}
      pending={financialPending}
      error={financialError}
      onClose={() => !financialPending && setFinancialModalOpen(false)}
      onSubmit={saveFinancialContract}
    />}
    {paymentInstallment && <PaymentModal
      installment={paymentInstallment}
      pending={paymentPending}
      error={paymentError}
      onClose={() => !paymentPending && setPaymentInstallment(null)}
      onSubmit={registerPayment}
    />}
  </section>
}

function ProcessIntelligencePanel({
  intelligence,
  analysis,
  actionAvailable,
  pending,
  error,
  onGenerate
}: {
  intelligence: Snapshot["intelligence"]
  analysis: AiAnalysis | null
  actionAvailable: boolean
  pending: boolean
  error: string | null
  onGenerate: () => Promise<void>
}) {
  const statusLabel = {
    stable: "Estável",
    attention: "Atenção",
    critical: "Crítico"
  }[intelligence.status]

  const priorityLabel = {
    low: "Baixa",
    medium: "Média",
    high: "Alta"
  }[intelligence.suggested_action.priority]

  return <section className={`react-legal-case-show__intelligence react-legal-case-show__intelligence--${intelligence.status}`} aria-labelledby="process-intelligence-heading">
    <div className="react-legal-case-show__intelligence-header">
      <div>
        <p className="react-legal-case-show__eyebrow">Análise operacional</p>
        <h2 id="process-intelligence-heading">Inteligência do processo</h2>
      </div>
      <div className="react-legal-case-show__intelligence-controls">
        <span className="react-legal-case-show__intelligence-status">{statusLabel}</span>
        {actionAvailable && <button type="button" className="react-legal-case-show__actions-button" onClick={() => void onGenerate()} disabled={pending} aria-busy={pending || undefined}>
          {pending ? "Gerando análise…" : "Gerar análise com IA"}
        </button>}
      </div>
    </div>

    <p className="react-legal-case-show__intelligence-summary">{intelligence.summary}</p>

    <article className="react-legal-case-show__intelligence-action">
      <p className="react-legal-case-show__intelligence-label">Próxima ação sugerida · Prioridade {priorityLabel}</p>
      <h3>{intelligence.suggested_action.title}</h3>
      <p>{intelligence.suggested_action.description}</p>
    </article>

    <div className="react-legal-case-show__intelligence-grid">
      <div>
        <h3>Pontos de atenção</h3>
        {intelligence.attention_points.length ? <div className="react-legal-case-show__intelligence-points">
          {intelligence.attention_points.map((point) => <article className={`react-legal-case-show__intelligence-point react-legal-case-show__intelligence-point--${point.severity}`} key={point.title}>
            <strong>{point.title}</strong>
            <p>{point.description}</p>
          </article>)}
        </div> : <p className="react-legal-case-show__intelligence-empty">Nenhum ponto crítico identificado.</p>}
      </div>

      <dl className="react-legal-case-show__intelligence-metrics">
        <div><dt>Eventos na timeline</dt><dd>{intelligence.metrics.timeline_events_count}</dd></div>
        <div><dt>Prazos pendentes</dt><dd>{intelligence.metrics.pending_deadlines_count}</dd></div>
        <div><dt>Prazos vencidos</dt><dd>{intelligence.metrics.overdue_deadlines_count}</dd></div>
        <div><dt>Tarefas pendentes</dt><dd>{intelligence.metrics.pending_tasks_count}</dd></div>
        <div><dt>Publicações pendentes</dt><dd>{intelligence.metrics.unread_publications_count}</dd></div>
        <div><dt>Próximo prazo</dt><dd>{intelligence.metrics.next_deadline_label}</dd></div>
      </dl>
    </div>

    {error && <p className="react-legal-case-show__intelligence-error" role="alert">{error}</p>}
    {analysis && <article className="react-legal-case-show__ai-analysis" aria-labelledby="ai-analysis-heading">
      <p className="react-legal-case-show__intelligence-label">Sugestão gerada por IA · Confiança {analysis.confidence}</p>
      <h3 id="ai-analysis-heading">Análise com IA</h3>
      <p>{analysis.summary}</p>
      {analysis.risks.length > 0 && <ul>
        {analysis.risks.map((risk) => <li key={risk}>{risk}</li>)}
      </ul>}
      <p><strong>Providência sugerida:</strong> {analysis.suggested_action}</p>
      <p className="react-legal-case-show__ai-disclaimer">{analysis.notes || "Sugestão gerada por IA. Revise antes de agir."}</p>
    </article>}
  </section>
}

function outcomeErrorMessage(body: { errors?: Record<string, string[] | string>; error?: string }) {
  if (body.error) return body.error

  const messages = Object.values(body.errors || {}).flatMap((value) => Array.isArray(value) ? value : [value])
  return messages.join(", ") || "Não foi possível registrar o desfecho."
}

function FinancialPanel({
  contract,
  installments,
  onConfigure,
  onRegisterPayment
}: {
  contract: FinancialContract | null
  installments: FinancialInstallment[]
  onConfigure: () => void
  onRegisterPayment: (installment: FinancialInstallment) => void
}) {
  const [expanded, setExpanded] = useState(false)

  return <section className="react-legal-case-show__financial" aria-labelledby="financial-heading">
    <div className="react-legal-case-show__financial-header">
      <div>
        <p className="react-legal-case-show__eyebrow">Honorários e recebimentos</p>
        <h2 id="financial-heading">Honorários do processo</h2>
      </div>
      <button type="button" className="react-legal-case-show__actions-button" onClick={onConfigure}>
        {contract ? "Editar honorários" : "Definir honorários"}
      </button>
    </div>
    {!contract && <p>Nenhum contrato financeiro configurado.</p>}
    {contract && <>
      <button type="button" className="react-legal-case-show__financial-toggle" aria-expanded={expanded} onClick={() => setExpanded((value) => !value)}>
        {expanded ? "Ocultar detalhes" : "Mostrar detalhes"}
      </button>
      {expanded && <>
      <dl className="react-legal-case-show__financial-summary">
        <div><dt>Honorários fixos</dt><dd>{contract.fixed_amount_label}</dd></div>
        <div><dt>Total contratado</dt><dd>{contract.total_amount_label}</dd></div>
        <div><dt>Parcelas</dt><dd>{contract.installment_count}x</dd></div>
        {contract.includes_percentage && <>
          <div><dt>Percentual adicional</dt><dd>{contract.percentage}%</dd></div>
          <div><dt>Base do percentual</dt><dd>{contract.percentage_basis_label}</dd></div>
          <div><dt>Valor-base</dt><dd>{contract.percentage_base_amount_label}</dd></div>
        </>}
      </dl>
      {contract.contract_document && <p className="react-legal-case-show__financial-document">Contrato: <a href={contract.contract_document.url} target="_blank" rel="noreferrer">{contract.contract_document.name}</a></p>}
      <div className="react-legal-case-show__financial-installments">
        <h3>Parcelas</h3>
        <ol>
          {installments.map((installment) => <li key={installment.id}>
            <span>{installment.number}ª parcela</span>
            <span>{installment.due_date_label}</span>
            <strong>{installment.amount_label}</strong>
            <span className={installment.status === "paid" ? "react-legal-case-show__financial-status react-legal-case-show__financial-status--paid" : "react-legal-case-show__financial-status"}>{installment.status_label}</span>
            {installment.payment ? <span className="react-legal-case-show__financial-payment">{installment.payment.payment_method_label} · {installment.payment.paid_at_label}{installment.payment.proof && <> · <a href={installment.payment.proof} target="_blank" rel="noreferrer">Comprovante</a></>}</span> : <button type="button" className="react-legal-case-show__financial-payment-button" onClick={() => onRegisterPayment(installment)}>Registrar recebimento</button>}
          </li>)}
        </ol>
      </div>
      </>}
    </>}
  </section>
}

function FinancialContractModal({
  legalCase,
  contract,
  installments,
  pending,
  error,
  onClose,
  onSubmit
}: {
  legalCase: Snapshot["case"]
  contract: FinancialContract | null
  installments: FinancialInstallment[]
  pending: boolean
  error: string | null
  onClose: () => void
  onSubmit: (formData: FormData) => Promise<void>
}) {
  const [fixedAmount, setFixedAmount] = useState(decimalString(contract?.fixed_amount))
  const [includesPercentage, setIncludesPercentage] = useState(contract?.includes_percentage || false)
  const [percentage, setPercentage] = useState(String(contract?.percentage || ""))
  const [percentageBasis, setPercentageBasis] = useState<"claim_value" | "client_received">(contract?.percentage_basis || "claim_value")
  const [clientReceivedAmount, setClientReceivedAmount] = useState(String(contract?.client_received_amount || ""))
  const [installmentCount, setInstallmentCount] = useState(String(contract?.installment_count || 1))
  const [firstDueDate, setFirstDueDate] = useState(contract?.first_due_date || installments[0]?.due_date || dateInputValue())
  const fixedNumber = parseFinancialNumber(fixedAmount)
  const percentageNumber = includesPercentage ? parseFinancialNumber(percentage) : 0
  const baseAmount = percentageBasis === "claim_value" ? parseFinancialNumber(legalCase.claim_value) : parseFinancialNumber(clientReceivedAmount)
  const totalAmount = fixedNumber + (includesPercentage ? baseAmount * percentageNumber / 100 : 0)
  const preserveInitialSchedule = useRef(installments.length > 0)
  const [installmentSchedule, setInstallmentSchedule] = useState<InstallmentInput[]>(() => {
    if (installments.length > 0) {
      return installments.map((installment) => ({
        amount: String(installment.amount),
        dueDate: installment.due_date || ""
      }))
    }

    return installmentPreview(totalAmount, Number(installmentCount), firstDueDate)
  })

  useEffect(() => {
    if (preserveInitialSchedule.current) {
      preserveInitialSchedule.current = false
      return
    }

    setInstallmentSchedule(installmentPreview(totalAmount, Number(installmentCount), firstDueDate))
  }, [totalAmount, installmentCount, firstDueDate])

  useEffect(() => {
    document.dispatchEvent(new Event("custom-select:refresh"))
  }, [includesPercentage])

  return <div className="react-legal-case-show__outcome-overlay" role="presentation" onMouseDown={(event) => {
    if (event.target === event.currentTarget) onClose()
  }}>
    <section className="react-legal-case-show__outcome-modal react-legal-case-show__financial-modal" role="dialog" aria-modal="true" aria-labelledby="financial-contract-modal-heading">
      <div className="react-legal-case-show__outcome-modal-header">
        <div>
          <p className="react-legal-case-show__eyebrow">Honorários do processo</p>
          <h2 id="financial-contract-modal-heading">Definir honorários e condições de pagamento</h2>
        </div>
        <button type="button" className="react-legal-case-show__outcome-close" onClick={onClose} disabled={pending} aria-label="Fechar contrato financeiro">×</button>
      </div>
      <p>Defina os honorários e a distribuição das parcelas. O valor fixo é obrigatório; o percentual é adicional.</p>
      <form className="app-form" onSubmit={(event) => {
        event.preventDefault()
        void onSubmit(new FormData(event.currentTarget))
      }}>
        <label htmlFor="financial-contract-fixed-amount">Valor fixo dos honorários</label>
        <CurrencyInput id="financial-contract-fixed-amount" name="financial_contract[fixed_amount]" value={fixedAmount} onChange={setFixedAmount} required disabled={pending} />

        <label className="react-legal-case-show__financial-check" htmlFor="financial-contract-includes-percentage"><input id="financial-contract-includes-percentage" name="financial_contract[includes_percentage]" type="checkbox" checked={includesPercentage} onChange={(event) => setIncludesPercentage(event.target.checked)} disabled={pending} /> Adicionar percentual de honorários</label>

        {includesPercentage && <>
          <label htmlFor="financial-contract-percentage">Percentual adicional</label>
          <div className="react-legal-case-show__percentage-input"><input id="financial-contract-percentage" name="financial_contract[percentage]" type="number" min="0.01" max="100" step="0.01" value={percentage} onChange={(event) => setPercentage(event.target.value)} required disabled={pending} /><span>%</span></div>

          <label htmlFor="financial-contract-percentage-basis">Base de cálculo</label>
          <select id="financial-contract-percentage-basis" name="financial_contract[percentage_basis]" value={percentageBasis} onChange={(event) => setPercentageBasis(event.target.value as "claim_value" | "client_received")} disabled={pending}>
            <option value="claim_value">Valor da causa</option>
            <option value="client_received">Valor recebido pelo cliente</option>
          </select>

          {percentageBasis === "client_received" && <>
            <label htmlFor="financial-contract-client-received">Valor recebido pelo cliente</label>
            <div className="react-legal-case-show__currency-input"><span>R$</span><input id="financial-contract-client-received" name="financial_contract[client_received_amount]" type="number" min="0" step="0.01" value={clientReceivedAmount} onChange={(event) => setClientReceivedAmount(event.target.value)} required disabled={pending} /></div>
          </>}
          {percentageBasis === "claim_value" && <p className="react-legal-case-show__financial-helper">Base atual: {formatCurrency(baseAmount)} (valor da causa).</p>}
        </>}

        <label htmlFor="financial-contract-installment-count">Quantidade de parcelas</label>
        <select id="financial-contract-installment-count" name="financial_contract[installment_count]" value={installmentCount} onChange={(event) => setInstallmentCount(event.target.value)} disabled={pending}>
          {Array.from({ length: 12 }, (_, index) => index + 1).map((count) => <option key={count} value={count}>{count}x</option>)}
        </select>

        <label htmlFor="financial-contract-first-due-date">Primeiro vencimento</label>
        <input id="financial-contract-first-due-date" name="financial_contract[first_due_date]" type="date" value={firstDueDate} onChange={(event) => setFirstDueDate(event.target.value)} required disabled={pending} />

        <label htmlFor="financial-contract-document">Contrato assinado</label>
        <FilePicker id="financial-contract-document" name="financial_contract[contract_document]" accept="application/pdf,image/*" disabled={pending} />

        <section className="react-legal-case-show__financial-preview" aria-live="polite">
          <h3>Prévia do contrato</h3>
          <p>Total previsto: <strong>{formatCurrency(totalAmount)}</strong></p>
          {installmentSchedule.length > 0 && <ol>{installmentSchedule.map((installment, index) => <li key={index}>
            <input type="hidden" name="financial_contract[installments][][number]" value={index + 1} />
            <label htmlFor={`financial-contract-installment-${index}-amount`}>Valor da {index + 1}ª parcela</label>
            <div className="react-legal-case-show__currency-input"><span>R$</span><input
              id={`financial-contract-installment-${index}-amount`}
              name="financial_contract[installments][][amount]"
              type="number"
              min="0.01"
              step="0.01"
              value={installment.amount}
              onChange={(event) => setInstallmentSchedule((current) => current.map((item, itemIndex) => itemIndex === index ? { ...item, amount: event.target.value } : item))}
              required
              disabled={pending}
            /></div>
            <label htmlFor={`financial-contract-installment-${index}-due-date`}>Vencimento da {index + 1}ª parcela</label>
            <input
              id={`financial-contract-installment-${index}-due-date`}
              name="financial_contract[installments][][due_date]"
              type="date"
              value={installment.dueDate}
              onChange={(event) => setInstallmentSchedule((current) => current.map((item, itemIndex) => itemIndex === index ? { ...item, dueDate: event.target.value } : item))}
              required
              disabled={pending}
            />
          </li>)}</ol>}
        </section>

        {error && <p className="react-legal-case-show__outcome-error" role="alert">{error}</p>}
        <div className="react-legal-case-show__outcome-modal-actions">
          <button type="button" onClick={onClose} disabled={pending}>Cancelar</button>
          <button type="submit" disabled={pending}>{pending ? "Salvando…" : "Salvar contrato"}</button>
        </div>
      </form>
    </section>
  </div>
}

function PaymentModal({
  installment,
  pending,
  error,
  onClose,
  onSubmit
}: {
  installment: FinancialInstallment
  pending: boolean
  error: string | null
  onClose: () => void
  onSubmit: (formData: FormData) => Promise<void>
}) {
  return <div className="react-legal-case-show__outcome-overlay" role="presentation" onMouseDown={(event) => {
    if (event.target === event.currentTarget) onClose()
  }}>
    <section className="react-legal-case-show__outcome-modal react-legal-case-show__financial-modal" role="dialog" aria-modal="true" aria-labelledby="financial-payment-modal-heading">
      <div className="react-legal-case-show__outcome-modal-header">
        <div>
          <p className="react-legal-case-show__eyebrow">Recebimento financeiro</p>
          <h2 id="financial-payment-modal-heading">Registrar recebimento</h2>
        </div>
        <button type="button" className="react-legal-case-show__outcome-close" onClick={onClose} disabled={pending} aria-label="Fechar recebimento">×</button>
      </div>
      <p>Parcela {installment.number} · <strong>{installment.amount_label}</strong>. O recebimento deve ser integral.</p>
      <form className="app-form" onSubmit={(event) => {
        event.preventDefault()
        void onSubmit(new FormData(event.currentTarget))
      }}>
        <label htmlFor="financial-payment-paid-at">Data e hora do pagamento</label>
        <input id="financial-payment-paid-at" name="payment[paid_at]" type="datetime-local" defaultValue={dateTimeInputValue()} required disabled={pending} />

        <label htmlFor="financial-payment-method">Forma de pagamento</label>
        <select id="financial-payment-method" name="payment[payment_method]" defaultValue="pix" required disabled={pending}>
          <option value="pix">Pix</option>
          <option value="cash">Dinheiro</option>
          <option value="credit_card">Cartão de crédito</option>
          <option value="debit_card">Cartão de débito</option>
        </select>

        <label htmlFor="financial-payment-proof">Comprovante de pagamento</label>
        <FilePicker id="financial-payment-proof" name="payment[proof]" accept="application/pdf,image/*" required disabled={pending} />

        {error && <p className="react-legal-case-show__outcome-error" role="alert">{error}</p>}
        <div className="react-legal-case-show__outcome-modal-actions">
          <button type="button" onClick={onClose} disabled={pending}>Cancelar</button>
          <button type="submit" disabled={pending}>{pending ? "Registrando…" : "Confirmar recebimento"}</button>
        </div>
      </form>
    </section>
  </div>
}

function parseFinancialNumber(value: string | number | null | undefined) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : 0
}

function decimalString(value: string | number | null | undefined) {
  const parsed = parseFinancialNumber(value)
  return parsed > 0 ? parsed.toFixed(2) : ""
}

function formatCurrencyInput(value: string | number | null | undefined) {
  const decimal = decimalString(value)
  if (!decimal) return ""

  const [whole, cents = "00"] = decimal.split(".")
  return `${whole.replace(/\B(?=(\d{3})+(?!\d))/g, ".")},${cents.padEnd(2, "0").slice(0, 2)}`
}

function currencyInputToDecimal(value: string) {
  let digits = value.replace(/\D/g, "").replace(/^0+/, "")
  if (!digits) return ""
  if (digits.length === 1) digits = `0${digits}`
  if (digits.length === 2) digits = `0${digits}`

  return `${Number(digits.slice(0, -2))}.${digits.slice(-2)}`
}

function CurrencyInput({
  id,
  name,
  value,
  onChange,
  required = false,
  disabled = false
}: {
  id: string
  name: string
  value: string
  onChange: (value: string) => void
  required?: boolean
  disabled?: boolean
}) {
  return <div className="react-legal-case-show__currency-input">
    <span>R$</span>
    <input
      id={id}
      type="text"
      inputMode="numeric"
      value={formatCurrencyInput(value)}
      onChange={(event) => onChange(currencyInputToDecimal(event.target.value))}
      required={required}
      disabled={disabled}
    />
    <input type="hidden" name={name} value={value} />
  </div>
}

function FilePicker({
  id,
  name,
  accept,
  required = false,
  disabled = false
}: {
  id: string
  name: string
  accept: string
  required?: boolean
  disabled?: boolean
}) {
  const [fileName, setFileName] = useState("")

  return <div className="react-legal-case-show__file-picker">
    <input
      id={id}
      className="react-legal-case-show__file-picker-input"
      name={name}
      type="file"
      accept={accept}
      required={required}
      disabled={disabled}
      onChange={(event) => setFileName(event.target.files?.[0]?.name || "")}
    />
    <label className="react-legal-case-show__file-picker-button" htmlFor={id}>Selecionar arquivo</label>
    <span className="react-legal-case-show__file-picker-name">{fileName || "Nenhum arquivo selecionado"}</span>
  </div>
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value || 0)
}

function formatOptionalCurrency(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "-"
  return formatCurrency(parseFinancialNumber(value))
}

function dateInputValue() {
  return new Date().toISOString().slice(0, 10)
}

function dateTimeInputValue() {
  const now = new Date()
  const local = new Date(now.getTime() - now.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 16)
}

type InstallmentInput = { amount: string; dueDate: string }

function installmentPreview(total: number, count: number, firstDueDate: string) {
  if (!Number.isInteger(count) || count < 1 || count > 12 || !firstDueDate || total <= 0) return []

  const cents = Math.round(total * 100)
  const baseCents = Math.floor(cents / count)
  const firstDate = new Date(`${firstDueDate}T12:00:00`)
  if (Number.isNaN(firstDate.getTime())) return []

  return Array.from({ length: count }, (_, index) => {
    const dueDate = new Date(firstDate)
    dueDate.setMonth(firstDate.getMonth() + index)
    const amountInCents = index === count - 1 ? cents - baseCents * (count - 1) : baseCents
    return {
      amount: (amountInCents / 100).toFixed(2),
      dueDate: dueDate.toISOString().slice(0, 10)
    }
  })
}

function OutcomeSummary({ legalCase }: { legalCase: Snapshot["case"] }) {
  return <section className="react-legal-case-show__outcome-summary" aria-labelledby="outcome-summary-heading">
    <h2 id="outcome-summary-heading">Desfecho do processo</h2>
    <p><strong>{legalCase.outcome_label}</strong></p>
    <dl>
      <div><dt>Data do desfecho</dt><dd>{legalCase.outcome_date_label}</dd></div>
      <div><dt>Registrado em</dt><dd>{legalCase.outcome_confirmed_at_label}</dd></div>
      <div><dt>Registrado por</dt><dd>{legalCase.outcome_confirmed_by_name || "Não informado"}</dd></div>
    </dl>
    {legalCase.outcome_notes && <p className="react-legal-case-show__outcome-notes">{legalCase.outcome_notes}</p>}
  </section>
}

function OutcomeModal({
  legalCase,
  pending,
  error,
  onClose,
  onSubmit
}: {
  legalCase: Snapshot["case"]
  pending: boolean
  error: string | null
  onClose: () => void
  onSubmit: (payload: { outcome: Outcome; outcomeDate: string; outcomeNotes: string }) => Promise<void>
}) {
  const [outcome, setOutcome] = useState<Outcome>(legalCase.outcome)
  const [outcomeDate, setOutcomeDate] = useState(legalCase.outcome_date || "")
  const [outcomeNotes, setOutcomeNotes] = useState(legalCase.outcome_notes || "")
  const selectRef = useRef<HTMLSelectElement>(null)

  useEffect(() => {
    selectRef.current?.focus()
    document.dispatchEvent(new Event("custom-select:refresh"))
  }, [])

  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose()
    }

    document.addEventListener("keydown", closeOnEscape)
    return () => document.removeEventListener("keydown", closeOnEscape)
  }, [onClose])

  return <div className="react-legal-case-show__outcome-overlay" role="presentation" onMouseDown={(event) => {
    if (event.target === event.currentTarget) onClose()
  }}>
    <section className="react-legal-case-show__outcome-modal" role="dialog" aria-modal="true" aria-labelledby="outcome-modal-heading" aria-describedby="outcome-modal-description">
      <div className="react-legal-case-show__outcome-modal-header">
        <div>
          <p className="react-legal-case-show__eyebrow">Ação administrativa</p>
          <h2 id="outcome-modal-heading">Registrar desfecho</h2>
        </div>
        <button type="button" className="react-legal-case-show__outcome-close" onClick={onClose} disabled={pending} aria-label="Fechar registro de desfecho">×</button>
      </div>
      <p id="outcome-modal-description">Registre o resultado jurídico. Um resultado ganho ativa apenas as cobranças que aguardam esse gatilho; nenhum pagamento será registrado automaticamente.</p>
      <form className="app-form" onSubmit={(event) => {
        event.preventDefault()
        void onSubmit({ outcome, outcomeDate, outcomeNotes })
      }}>
        <label htmlFor="legal-case-outcome">Resultado</label>
        <select id="legal-case-outcome" ref={selectRef} value={outcome} onChange={(event) => setOutcome(event.target.value as Outcome)} disabled={pending}>
          {outcomeOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
        </select>

        <label htmlFor="legal-case-outcome-date">Data do desfecho</label>
        <input id="legal-case-outcome-date" type="date" value={outcomeDate} onChange={(event) => setOutcomeDate(event.target.value)} disabled={pending} required />

        <label htmlFor="legal-case-outcome-notes">Observação</label>
        <textarea id="legal-case-outcome-notes" value={outcomeNotes} onChange={(event) => setOutcomeNotes(event.target.value)} disabled={pending} rows={4} />

        {error && <p className="react-legal-case-show__outcome-error" role="alert">{error}</p>}
        <div className="react-legal-case-show__outcome-modal-actions">
          <button type="button" onClick={onClose} disabled={pending}>Cancelar</button>
          <button type="submit" disabled={pending} aria-busy={pending || undefined}>
            {pending && <span className="react-legal-case-show__sync-spinner" aria-hidden="true" />}
            {pending ? "Registrando…" : "Confirmar desfecho"}
          </button>
        </div>
      </form>
    </section>
  </div>
}

function AlertSummary({ alerts }: { alerts: Snapshot["alerts"] }) {
  const alertLabels = [
    alerts.deadline_overdue && "Prazo vencido",
    alerts.deadline_near && "Prazo próximo",
    alerts.exam_pending && "Perícia pendente",
    alerts.next_action_warning && "Providência pendente",
    alerts.stale_last_movement && "Andamento desatualizado",
    alerts.has_new_imported_events && "Novos andamentos"
  ].filter((label): label is string => Boolean(label))

  return <>
    <span className={`react-legal-case-show__badge react-legal-case-show__badge--health react-legal-case-show__badge--health-${alerts.health_status}`}>Saúde: {alerts.health_status}</span>
    {alertLabels.map((label) => <span className="react-legal-case-show__badge react-legal-case-show__badge--alert" key={label}>{label}</span>)}
  </>
}

function OperationalSection({ title, hasAlert, children }: { title: string; hasAlert: boolean; children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(hasAlert)
  const contentId = `legal-case-show-${title.toLocaleLowerCase("pt-BR")}`

  return <section className="react-legal-case-show__operational-section">
    <h2><button type="button" data-testid={contentId} aria-expanded={isOpen} aria-controls={contentId} onClick={() => setIsOpen((open) => !open)}><span>{title}</span><span aria-hidden="true">{isOpen ? "−" : "+"}</span></button></h2>
    <div className="react-legal-case-show__operational-content" id={contentId} hidden={!isOpen}>{children}</div>
  </section>
}

function CollectionEmpty<T>({ items, message, children }: { items: T[]; message: string; children: React.ReactNode }) {
  return items.length ? <>{children}</> : <p>{message}</p>
}

function SyncForm({ action, onSync, pending }: { action: NonNullable<Snapshot["actions"]["sync"]>; onSync: (action: NonNullable<Snapshot["actions"]["sync"]>) => Promise<void>; pending: boolean }) {
  return <form className="react-legal-case-show__sync-form" onSubmit={(event) => {
    event.preventDefault()
    void onSync(action)
  }}>
    <button type="submit" disabled={pending}>
      {pending && <span className="react-legal-case-show__sync-spinner" aria-hidden="true" />}
      {pending ? "Buscando andamentos…" : "Atualizar andamentos"}
    </button>
  </form>
}
