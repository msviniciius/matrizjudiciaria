import { useEffect, useRef, useState } from "react"
import "./internalCalendar.css"

type ViewMode = "month" | "list"
type CalendarEvent = {
  type: "deadline" | "task" | "exam" | string
  type_label: string
  date: string
  date_label: string
  time: string | null
  time_label: string
  title: string
  process_label: string
  detail: string
  url: string
  display_title: string
}
type CalendarDay = {
  date: string
  day_number: number
  outside_month: boolean
  today: boolean
  events: CalendarEvent[]
}
type Snapshot = {
  meta: {
    view_mode: ViewMode
    reference_month: string
    month_label: string
    today_month: string
    total_count: number
  }
  weekdays: string[]
  weeks: CalendarDay[][]
  events: CalendarEvent[]
  actions: {
    index: string
    month: string
    list: string
    previous_month: string
    next_month: string
    today: string
    google_calendar: string | null
  }
}

function paramsFromLocation() {
  const parameters = new URLSearchParams(window.location.search)
  return {
    month: parameters.get("month") || "",
    view: parameters.get("view") === "list" ? "list" : "month"
  }
}

function paramsFor(month: string, view: ViewMode) {
  const parameters = new URLSearchParams()
  if (month) parameters.set("month", month)
  parameters.set("view", view)
  return parameters
}

function fetchSnapshot(month: string, view: ViewMode, signal?: AbortSignal): Promise<Snapshot> {
  return fetch(`/calendario_interno.json?${paramsFor(month, view)}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function InternalCalendarApp() {
  const initialParams = paramsFromLocation()
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [month, setMonth] = useState(initialParams.month)
  const [view, setView] = useState<ViewMode>(initialParams.view as ViewMode)
  const [error, setError] = useState<string | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(true)
  const requestRef = useRef({ id: 0, controller: null as AbortController | null })

  const requestSnapshot = (nextMonth: string, nextView: ViewMode) => {
    requestRef.current.controller?.abort()
    const controller = new AbortController()
    const id = requestRef.current.id + 1
    requestRef.current = { id, controller }
    setError(null)
    setIsRefreshing(true)

    fetchSnapshot(nextMonth, nextView, controller.signal)
      .then((nextSnapshot) => {
        if (requestRef.current.id !== id) return
        setSnapshot(nextSnapshot)
        setMonth(nextSnapshot.meta.reference_month)
        setView(nextSnapshot.meta.view_mode)
      })
      .catch((reason: unknown) => {
        if (requestRef.current.id !== id || (reason instanceof DOMException && reason.name === "AbortError")) return
        setError("Não foi possível atualizar o calendário. Tente novamente.")
      })
      .finally(() => {
        if (requestRef.current.id === id) setIsRefreshing(false)
      })
  }

  useEffect(() => {
    requestSnapshot(month, view)
    return () => requestRef.current.controller?.abort()
  }, [])

  const navigate = (nextMonth: string, nextView: ViewMode) => {
    const parameters = paramsFor(nextMonth, nextView)
    window.history.replaceState({}, "", `${window.location.pathname}?${parameters}`)
    setMonth(nextMonth)
    setView(nextView)
    requestSnapshot(nextMonth, nextView)
  }

  const activeMonth = snapshot?.meta.reference_month || month
  const activeView = snapshot?.meta.view_mode || view

  return <div className="react-internal-calendar" aria-label="Calendário interno">
    <header className="react-internal-calendar__header">
      <div>
        <p className="react-internal-calendar__eyebrow">Agenda operacional</p>
        <h1>Calendário interno</h1>
        {snapshot && <p className="react-internal-calendar__count" role="status">{snapshot.meta.month_label} · {snapshot.meta.total_count} item(ns)</p>}
      </div>
      <div className="react-internal-calendar__header-actions">
        <div className="react-internal-calendar__view-switch" aria-label="Visualização">
          <button type="button" aria-pressed={activeView === "month"} onClick={() => navigate(activeMonth, "month")}>Calendário</button>
          <button type="button" aria-pressed={activeView === "list"} onClick={() => navigate(activeMonth, "list")}>Lista</button>
        </div>
        {snapshot?.actions.google_calendar && <a className="react-internal-calendar__subscribe" href={snapshot.actions.google_calendar} target="_blank" rel="noreferrer">Assinar no Google Calendar</a>}
      </div>
    </header>

    {snapshot && <nav className="react-internal-calendar__nav" aria-label="Navegação do calendário">
      <button type="button" onClick={() => navigate(monthFromAction(snapshot.actions.previous_month), activeView)}>Mês anterior</button>
      <button type="button" onClick={() => navigate(snapshot.meta.today_month, activeView)}>Hoje</button>
      <button type="button" onClick={() => navigate(monthFromAction(snapshot.actions.next_month), activeView)}>Próximo mês</button>
    </nav>}

    {isRefreshing && <div className="react-internal-calendar__loading" role="status"><span aria-hidden="true" className="react-internal-calendar__loading-mark" />{snapshot ? "Atualizando calendário..." : "Carregando calendário..."}</div>}
    {!snapshot && isRefreshing && <LoadingSkeleton />}
    {error && <section className="react-internal-calendar__error" role="alert"><p>{error}</p><button type="button" onClick={() => requestSnapshot(month, view)}>Tentar novamente</button></section>}
    {snapshot && (activeView === "month" ? <MonthView snapshot={snapshot} /> : <ListView events={snapshot.events} />)}
  </div>
}

function monthFromAction(path: string) {
  return new URL(path, window.location.origin).searchParams.get("month") || ""
}

function MonthView({ snapshot }: { snapshot: Snapshot }) {
  return <section className="react-internal-calendar__month" aria-label={snapshot.meta.month_label}>
    <div className="react-internal-calendar__weekdays">
      {snapshot.weekdays.map((weekday) => <div className="react-internal-calendar__weekday" key={weekday}>{weekday}</div>)}
    </div>
    {snapshot.weeks.map((week, index) => <div className="react-internal-calendar__week" key={`week-${index}`}>
      {week.map((day) => <article className={dayClassName(day)} key={day.date} aria-label={`${day.day_number}`}>
        <header className="react-internal-calendar__day-head">
          <strong>{day.day_number}</strong>
          {day.today && <span>Hoje</span>}
        </header>
        {day.events.length ? <ul className="react-internal-calendar__events">
          {day.events.slice(0, 2).map((event) => <li key={`${event.type}-${event.url}-${event.title}`}><CalendarEventLink event={event} /></li>)}
        </ul> : <p className="react-internal-calendar__empty-day">Sem itens.</p>}
        {day.events.length > 2 && <p className="react-internal-calendar__more">+{day.events.length - 2} item(ns)</p>}
      </article>)}
    </div>)}
  </section>
}

function dayClassName(day: CalendarDay) {
  return ["react-internal-calendar__day", day.outside_month ? "is-outside-month" : "", day.today ? "is-today" : ""].filter(Boolean).join(" ")
}

function CalendarEventLink({ event }: { event: CalendarEvent }) {
  return <a className={`react-internal-calendar__event-link react-internal-calendar__event-link--${event.type}`} href={event.url}>
    <span>{event.display_title}</span>
    {event.time_label !== "-" && <small>{event.time_label}</small>}
  </a>
}

function ListView({ events }: { events: CalendarEvent[] }) {
  if (!events.length) return <EmptyState />
  return <div className="react-internal-calendar__table-wrap"><table className="react-internal-calendar__table" aria-label="Lista do calendário interno">
    <thead><tr><th>Data</th><th>Hora</th><th>Tipo</th><th>Título</th><th>Processo</th><th>Detalhe</th><th>Ações</th></tr></thead>
    <tbody>{events.map((event) => <tr key={`${event.type}-${event.date}-${event.title}-${event.url}`}>
      <td>{event.date_label}</td>
      <td>{event.time_label}</td>
      <td>{event.type_label}</td>
      <td>{event.title}</td>
      <td>{event.process_label}</td>
      <td>{event.detail}</td>
      <td><a href={event.url} aria-label={`Ver item ${event.title}`}>Ver</a></td>
    </tr>)}</tbody>
  </table></div>
}

function LoadingSkeleton() {
  return <section className="react-internal-calendar__skeleton" aria-hidden="true"><span /><span /><span /></section>
}

function EmptyState() {
  return <section className="react-internal-calendar__empty"><h2>Nenhum item no período selecionado.</h2><p>Navegue para outro mês para consultar compromissos, prazos e perícias.</p></section>
}
