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
    record_outcome: { path: string; method: string } | null
  }
  permissions: { can_record_outcome: boolean }
}

type Outcome = "undefined" | "won" | "lost" | "settled" | "partially_won"

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

  const interactionLocked = syncPending || outcomeModalOpen

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
      const body = await response.json().catch(() => ({})) as { errors?: Record<string, string[] | string>; error?: string }
      if (!response.ok) throw new Error(outcomeErrorMessage(body))

      const refreshedSnapshot = await fetchSnapshot()
      setSnapshot(refreshedSnapshot)
      restoreOutcomeButtonFocus.current = true
      setOutcomeModalOpen(false)
      setOutcomeMessage("Desfecho do processo registrado com sucesso.")
    } catch (outcomeFailure) {
      setOutcomeError(outcomeFailure instanceof Error ? outcomeFailure.message : "Não foi possível registrar o desfecho.")
    } finally {
      setOutcomePending(false)
    }
  }

  const visibleTimeline = showAllTimeline ? snapshot.timeline : snapshot.timeline.slice(0, 5)
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
      <div className="react-legal-case-show__header-actions"><div className="react-legal-case-show__actions">{snapshot.permissions.can_record_outcome && snapshot.actions.record_outcome && <button className="react-legal-case-show__outcome-action" type="button" onClick={openOutcomeModal} ref={outcomeButtonRef}>Registrar desfecho</button>}<a href={snapshot.actions.edit}>Editar processo</a><a href={snapshot.actions.pdf} target="_blank" rel="noreferrer">Exportar PDF</a><a href={snapshot.actions.index}>Voltar</a></div><div className="react-legal-case-show__badges" aria-label="Situação do processo">
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

    <div className="react-legal-case-show__layout">
    <div className="react-legal-case-show__main-column">
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

    <section className="react-legal-case-show__timeline" aria-labelledby="timeline-heading">
      <h2 id="timeline-heading">Timeline</h2>
      {visibleTimeline.length ? <ol>
        {visibleTimeline.map((item) => <li className={item.highlight ? "react-legal-case-show__timeline-item react-legal-case-show__timeline-item--highlight" : "react-legal-case-show__timeline-item"} key={`${item.source}-${item.id}`}>
          <p className="react-legal-case-show__timeline-meta">{item.source_label || item.source} · {item.occurred_at_label}</p>
          <h3>{item.title}</h3>
          {item.description && <p>{item.description}</p>}
          {item.movement_type && <p>{item.movement_type}</p>}
          {item.exam_summary && <p>Perícia: {item.exam_summary}</p>}
        </li>)}
      </ol> : <p>Nenhum andamento cadastrado.</p>}
      {remainingTimelineItems > 0 && <button className="react-legal-case-show__timeline-more" type="button" onClick={() => setShowAllTimeline(true)}>Mostrar mais {remainingTimelineItems} andamento(s) anterior(es)</button>}
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
        <div><dt>Valor da causa</dt><dd>{snapshot.case.claim_value || "-"}</dd></div>
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
  </section>
}

function outcomeErrorMessage(body: { errors?: Record<string, string[] | string>; error?: string }) {
  if (body.error) return body.error

  const messages = Object.values(body.errors || {}).flatMap((value) => Array.isArray(value) ? value : [value])
  return messages.join(", ") || "Não foi possível registrar o desfecho."
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
      <form onSubmit={(event) => {
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
    <h2><button type="button" aria-expanded={isOpen} aria-controls={contentId} onClick={() => setIsOpen((open) => !open)}><span>{title}</span><span aria-hidden="true">{isOpen ? "−" : "+"}</span></button></h2>
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
