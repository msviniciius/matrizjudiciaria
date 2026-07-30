/// <reference path="../vite-env.d.ts" />

import { useEffect, useState } from "react"
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
  }
}

function fetchSnapshot(): Promise<Snapshot> {
  return fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function LegalCaseShowApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [showAllTimeline, setShowAllTimeline] = useState(false)

  const loadSnapshot = () => {
    setError(null)
    setIsLoading(true)
    fetchSnapshot()
      .then((nextSnapshot) => {
        setSnapshot(nextSnapshot)
        setShowAllTimeline(false)
      })
      .catch(() => setError("Não foi possível carregar os dados do processo. Tente novamente."))
      .finally(() => setIsLoading(false))
  }

  useEffect(() => {
    loadSnapshot()
  }, [])

  if (isLoading && !snapshot) {
    return <section className="react-legal-case-show react-legal-case-show--loading" aria-label="Central de comando"><p role="status">Carregando processo…</p></section>
  }

  if (error && !snapshot) {
    return <section className="react-legal-case-show react-legal-case-show--loading" aria-label="Central de comando"><section className="react-legal-case-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section></section>
  }

  if (!snapshot) return null

  const visibleTimeline = showAllTimeline ? snapshot.timeline : snapshot.timeline.slice(0, 5)
  const remainingTimelineItems = snapshot.timeline.length - visibleTimeline.length
  const deadlineAlert = snapshot.alerts.deadline_near || snapshot.alerts.deadline_overdue

  return <section className="react-legal-case-show" aria-label="Central de comando">
    <header className="react-legal-case-show__header">
      <div>
        <p className="react-legal-case-show__eyebrow">Processo {snapshot.case.internal_number}</p>
        <h1>Central de comando</h1>
        <p className="react-legal-case-show__client">{snapshot.case.client_name}</p>
        <p className="react-legal-case-show__identifiers">{snapshot.case.external_number ? `CNJ: ${snapshot.case.external_number}` : "Sem número CNJ"}</p>
      </div>
      <div className="react-legal-case-show__badges" aria-label="Situação do processo">
        <span className="react-legal-case-show__badge">{snapshot.case.phase_label}</span>
        <span className="react-legal-case-show__badge">{snapshot.case.status_label}</span>
        <span className="react-legal-case-show__badge react-legal-case-show__badge--priority">Prioridade {snapshot.case.priority_label}</span>
        <AlertSummary alerts={snapshot.alerts} />
      </div>
    </header>

    {error && <section className="react-legal-case-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section>}
    {isLoading && <p className="react-legal-case-show__refreshing" role="status">Atualizando processo…</p>}

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
        <a href={snapshot.actions.edit}>Editar processo</a>
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

    <nav className="react-legal-case-show__shortcuts" aria-label="Atalhos do processo">
      <a href={snapshot.actions.pdf}>Exportar PDF</a>
      <a href={snapshot.actions.calendar}>Adicionar ao calendário</a>
      <a href={snapshot.actions.index}>Voltar aos processos</a>
      {snapshot.actions.sync && <SyncForm action={snapshot.actions.sync} />}
    </nav>
    </aside>
    </div>
  </section>
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

function SyncForm({ action }: { action: NonNullable<Snapshot["actions"]["sync"]> }) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

  return <form className="react-legal-case-show__sync-form" action={action.path} method={action.method}>
    {csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}
    <button type="submit">Atualizar andamentos</button>
  </form>
}
