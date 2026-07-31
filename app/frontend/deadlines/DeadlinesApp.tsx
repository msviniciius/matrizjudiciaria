import { useEffect, useRef, useState } from "react"
import "./deadlines.css"

type View = "cards" | "table"
type FilterKey = "q" | "status" | "priority" | "deadline_type" | "due_state"
type Filters = Record<FilterKey, string>
type Option = { value: string; label: string }
type Deadline = {
  id: number
  path: string
  edit_path: string
  delete_path: string
  legal_case_path: string | null
  process_number: string
  client_name: string
  title: string
  deadline_type_label: string
  due_date_label: string
  due_state: string
  due_state_label: string
  status: string
  status_label: string
  priority: string | null
  priority_label: string
  extended_at_label: string
  responsible_name: string
  delay_reason: string
}
type Snapshot = {
  meta: { office_name: string; unit_name?: string | null; total_count: number }
  filters: Filters
  filter_options: {
    statuses: Option[]
    priorities: Option[]
    deadline_types: Option[]
    due_states: Option[]
  }
  deadlines: Deadline[]
  actions: { index: string; new: string }
}

const VIEW_KEY = "deadlines-view"
const FILTER_KEYS: FilterKey[] = ["q", "status", "priority", "deadline_type", "due_state"]

function emptyFilters(): Filters {
  return FILTER_KEYS.reduce((filters, key) => ({ ...filters, [key]: "" }), {} as Filters)
}

function filtersFromLocation(): Filters {
  const parameters = new URLSearchParams(window.location.search)
  return FILTER_KEYS.reduce((filters, key) => ({ ...filters, [key]: parameters.get(key) || "" }), emptyFilters())
}

function paramsFor(filters: Filters) {
  const parameters = new URLSearchParams()
  FILTER_KEYS.forEach((key) => {
    if (filters[key]) parameters.set(key, filters[key])
  })
  return parameters
}

function savedView(): View {
  return sessionStorage.getItem(VIEW_KEY) === "table" ? "table" : "cards"
}

function fetchSnapshot(filters: URLSearchParams, signal?: AbortSignal): Promise<Snapshot> {
  return fetch(`/deadlines.json?${filters}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function DeadlinesApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [filters, setFilters] = useState<Filters>(filtersFromLocation)
  const [draftQuery, setDraftQuery] = useState(() => filtersFromLocation().q)
  const [view, setView] = useState<View>(savedView)
  const [error, setError] = useState<string | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(true)
  const requestRef = useRef({ id: 0, controller: null as AbortController | null })

  const requestSnapshot = (nextFilters: Filters) => {
    requestRef.current.controller?.abort()
    const controller = new AbortController()
    const id = requestRef.current.id + 1
    requestRef.current = { id, controller }
    setError(null)
    setIsRefreshing(true)
    const requestedQuery = nextFilters.q

    fetchSnapshot(paramsFor(nextFilters), controller.signal)
      .then((nextSnapshot) => {
        if (requestRef.current.id !== id) return
        setSnapshot(nextSnapshot)
        setFilters(nextSnapshot.filters)
        setDraftQuery((currentQuery) => currentQuery === requestedQuery ? nextSnapshot.filters.q : currentQuery)
      })
      .catch((reason: unknown) => {
        if (requestRef.current.id !== id || (reason instanceof DOMException && reason.name === "AbortError")) return
        setError("Não foi possível atualizar os prazos. Tente novamente.")
      })
      .finally(() => {
        if (requestRef.current.id === id) setIsRefreshing(false)
      })
  }

  useEffect(() => {
    requestSnapshot(filters)
    return () => requestRef.current.controller?.abort()
  }, [])

  const updateFilter = (key: FilterKey, value: string) => {
    const nextFilters = { ...filters, [key]: value }
    const parameters = paramsFor(nextFilters)
    window.history.replaceState({}, "", `${window.location.pathname}?${parameters}`)
    setFilters(nextFilters)
    requestSnapshot(nextFilters)
  }

  const clearFilters = () => {
    const nextFilters = emptyFilters()
    window.history.replaceState({}, "", window.location.pathname)
    setFilters(nextFilters)
    setDraftQuery("")
    requestSnapshot(nextFilters)
  }

  const chooseView = (nextView: View) => {
    setView(nextView)
    sessionStorage.setItem(VIEW_KEY, nextView)
  }

  return <div className="react-deadlines" aria-label="Prazos">
    <header className="react-deadlines__header">
      <div>
        <p className="react-deadlines__eyebrow">{snapshot?.meta.unit_name || snapshot?.meta.office_name || "Operação jurídica"}</p>
        <h1>Prazos</h1>
        {snapshot && <p className="react-deadlines__count" role="status">{snapshot.meta.total_count} prazo(s)</p>}
      </div>
      <div className="react-deadlines__header-actions">
        {snapshot?.actions.new && <a className="react-deadlines__new" href={snapshot.actions.new}>Novo prazo</a>}
        <div className="react-deadlines__view-switch" aria-label="Visualização">
        <button type="button" aria-pressed={view === "cards"} onClick={() => chooseView("cards")}>Cartões</button>
        <button type="button" aria-pressed={view === "table"} onClick={() => chooseView("table")}>Tabela</button>
        </div>
      </div>
    </header>

    {snapshot && <FiltersForm filters={filters} options={snapshot.filter_options} query={draftQuery} onChange={updateFilter} onQueryChange={setDraftQuery} onSearch={(query) => updateFilter("q", query)} onClear={clearFilters} />}
    {isRefreshing && <div className="react-deadlines__loading" role="status"><span aria-hidden="true" className="react-deadlines__loading-mark" />{snapshot ? "Atualizando prazos..." : "Carregando prazos..."}</div>}
    {!snapshot && isRefreshing && <LoadingSkeleton />}
    {error && <section className="react-deadlines__error" role="alert"><p>{error}</p><button type="button" onClick={() => requestSnapshot(filters)}>Tentar novamente</button></section>}
    {snapshot && (view === "cards" ? <Cards deadlines={snapshot.deadlines} /> : <DeadlinesTable deadlines={snapshot.deadlines} />)}
  </div>
}

function FiltersForm({ filters, options, query, onChange, onQueryChange, onSearch, onClear }: { filters: Filters; options: Snapshot["filter_options"]; query: string; onChange: (key: FilterKey, value: string) => void; onQueryChange: (value: string) => void; onSearch: (value: string) => void; onClear: () => void }) {
  const [advancedOpen, setAdvancedOpen] = useState(false)
  const advancedFiltersId = "deadlines-advanced-filters"

  return <form className="react-deadlines__filters" aria-label="Filtros de prazos" onSubmit={(event) => { event.preventDefault(); onSearch(query) }}>
    <div className="react-deadlines__search-row">
      <label className="react-deadlines__search">Busca<input value={query} placeholder="Processo, título ou responsável" onChange={(event) => onQueryChange(event.target.value)} /></label>
      <button className="react-deadlines__search-submit" type="submit">Buscar</button>
      <button className="react-deadlines__advanced-toggle" type="button" aria-expanded={advancedOpen} aria-controls={advancedFiltersId} onClick={() => setAdvancedOpen((open) => !open)}>Filtros avançados</button>
      <button className="react-deadlines__clear" type="button" onClick={onClear}>Limpar filtros</button>
    </div>
    <div className="react-deadlines__advanced-filters" id={advancedFiltersId} hidden={!advancedOpen}>
      <SelectFilter label="Status" value={filters.status} options={options.statuses} blank="Todos" onChange={(value) => onChange("status", value)} />
      <SelectFilter label="Prioridade" value={filters.priority} options={options.priorities} blank="Todas" onChange={(value) => onChange("priority", value)} />
      <SelectFilter label="Tipo de prazo" value={filters.deadline_type} options={options.deadline_types} blank="Todos" onChange={(value) => onChange("deadline_type", value)} />
      <SelectFilter label="Situação da data" value={filters.due_state} options={options.due_states} blank="Todas" onChange={(value) => onChange("due_state", value)} />
    </div>
  </form>
}

function SelectFilter({ label, value, options, blank, onChange }: { label: string; value: string; options: Option[]; blank: string; onChange: (value: string) => void }) {
  return <label>{label}<select value={value} onChange={(event) => onChange(event.target.value)}><option value="">{blank}</option>{options.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select></label>
}

function Cards({ deadlines }: { deadlines: Deadline[] }) {
  if (!deadlines.length) return <EmptyState />
  return <section className="react-deadlines__cards" aria-label="Listagem de prazos">{deadlines.map((deadline) => <article className="react-deadlines__card" aria-label={deadline.title} key={deadline.id}>
    <div className="react-deadlines__card-head"><h2><a href={deadline.path}>{deadline.title}</a></h2><span className={`react-deadlines__badge react-deadlines__badge--${deadline.due_state}`}>{deadline.due_state_label}</span></div>
    <p className="react-deadlines__document">{deadline.legal_case_path ? <a href={deadline.legal_case_path}>{deadline.process_number}</a> : deadline.process_number} · {deadline.client_name}</p>
    <dl><div><dt>Data limite</dt><dd>{deadline.due_date_label}</dd></div><div><dt>Status</dt><dd>{deadline.status_label}</dd></div><div><dt>Tipo</dt><dd>{deadline.deadline_type_label}</dd></div><div><dt>Prioridade</dt><dd>{deadline.priority_label}</dd></div><div><dt>Responsável</dt><dd>{deadline.responsible_name}</dd></div><div><dt>Prorrogado em</dt><dd>{deadline.extended_at_label}</dd></div></dl>
    {deadline.delay_reason && <p className="react-deadlines__reason">{deadline.delay_reason}</p>}
    <DeadlineActions deadline={deadline} />
  </article>)}</section>
}

function DeadlinesTable({ deadlines }: { deadlines: Deadline[] }) {
  if (!deadlines.length) return <EmptyState />
  return <div className="react-deadlines__table-wrap"><table className="react-deadlines__table" aria-label="Listagem de prazos">
    <thead><tr><th>Processo</th><th>Título</th><th>Tipo</th><th>Data limite</th><th>Status</th><th>Prorrogado em</th><th>Prioridade</th><th>Responsável</th><th>Ações</th></tr></thead>
    <tbody>{deadlines.map((deadline) => <tr key={deadline.id}><td>{deadline.legal_case_path ? <a href={deadline.legal_case_path}>{deadline.process_number}</a> : deadline.process_number}</td><td><a href={deadline.path}>{deadline.title}</a></td><td>{deadline.deadline_type_label}</td><td>{deadline.due_date_label}</td><td><span className={`react-deadlines__badge react-deadlines__badge--${deadline.due_state}`}>{deadline.status_label}</span></td><td>{deadline.extended_at_label}</td><td>{deadline.priority_label}</td><td>{deadline.responsible_name}</td><td><DeadlineActions deadline={deadline} compact /></td></tr>)}</tbody>
  </table></div>
}

function DeadlineActions({ deadline, compact = false }: { deadline: Deadline; compact?: boolean }) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
  const className = compact ? "react-deadlines__actions react-deadlines__actions--compact" : "react-deadlines__actions"
  return <div className={className}>
    <a href={deadline.edit_path} aria-label={`Editar prazo ${deadline.title}`}>Editar</a>
    <form action={deadline.delete_path} method="post" onSubmit={(event) => { if (!window.confirm("Excluir este prazo?")) event.preventDefault() }}>
      <input type="hidden" name="_method" value="delete" />
      {csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}
      <button type="submit" aria-label={`Excluir prazo ${deadline.title}`}>Excluir</button>
    </form>
  </div>
}

function LoadingSkeleton() {
  return <section className="react-deadlines__skeleton" aria-hidden="true"><span /><span /><span /></section>
}

function EmptyState() {
  return <section className="react-deadlines__empty"><h2>Nenhum prazo encontrado para estes filtros.</h2><p>Ajuste ou limpe os filtros para consultar outros prazos.</p></section>
}
