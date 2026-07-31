import { useEffect, useRef, useState } from "react"
import "./processMovements.css"

type View = "cards" | "table"
type FilterKey = "q" | "phase_id" | "status" | "movement_type_id" | "nature" | "impact" | "origin" | "from" | "to" | "responsible_name" | "exam_id" | "administrative_situation"
type Filters = Record<FilterKey, string>
type Option = { value: string; label: string }
type ReportEntry = { label: string; count: number }
type ReportGroup = { title: string; total: number; entries: ReportEntry[] }
type Movement = {
  id: number
  path: string
  edit_path: string
  legal_case_path: string | null
  process_number: string
  client_name: string
  phase_name: string
  status_label: string
  movement_type_name: string
  display_title: string
  description: string
  event_date_label: string
  nature_label: string
  impact_label: string
  origin_label: string
  administrative_situation_label: string
  responsible_name: string
}
type Snapshot = {
  meta: { office_name: string; total_count: number }
  filters: Filters
  filter_options: {
    phases: Option[]
    statuses: Option[]
    movement_types: Option[]
    natures: Option[]
    impacts: Option[]
    origins: Option[]
    exams: Option[]
    administrative_situations: Option[]
  }
  reports: Record<string, ReportGroup>
  process_movements: Movement[]
  actions: { index: string; new: string }
}

const VIEW_KEY = "process-movements-view"
const FILTER_KEYS: FilterKey[] = ["q", "phase_id", "status", "movement_type_id", "nature", "impact", "origin", "from", "to", "responsible_name", "exam_id", "administrative_situation"]

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
  return fetch(`/process_movements.json?${filters}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function ProcessMovementsApp() {
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
        setError("Não foi possível atualizar os andamentos. Tente novamente.")
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

  return <div className="react-process-movements" aria-label="Andamentos processuais">
    <header className="react-process-movements__header">
      <div>
        <p className="react-process-movements__eyebrow">{snapshot?.meta.office_name || "Operação jurídica"}</p>
        <h1>Andamentos processuais</h1>
        {snapshot && <p className="react-process-movements__count" role="status">{snapshot.meta.total_count} andamento(s)</p>}
      </div>
      <div className="react-process-movements__header-actions">
        <div className="react-process-movements__view-switch" aria-label="Visualização">
          <button type="button" aria-pressed={view === "cards"} onClick={() => chooseView("cards")}>Cartões</button>
          <button type="button" aria-pressed={view === "table"} onClick={() => chooseView("table")}>Tabela</button>
        </div>
        {snapshot && <a className="react-process-movements__new" href={snapshot.actions.new}>Novo andamento</a>}
      </div>
    </header>

    {snapshot && <FiltersForm filters={filters} options={snapshot.filter_options} query={draftQuery} onChange={updateFilter} onQueryChange={setDraftQuery} onSearch={(query) => updateFilter("q", query)} onClear={clearFilters} />}
    {snapshot && <Reports reports={snapshot.reports} />}
    {isRefreshing && <div className="react-process-movements__loading" role="status"><span aria-hidden="true" className="react-process-movements__loading-mark" />{snapshot ? "Atualizando andamentos..." : "Carregando andamentos..."}</div>}
    {!snapshot && isRefreshing && <LoadingSkeleton />}
    {error && <section className="react-process-movements__error" role="alert"><p>{error}</p><button type="button" onClick={() => requestSnapshot(filters)}>Tentar novamente</button></section>}
    {snapshot && (view === "cards" ? <Cards movements={snapshot.process_movements} /> : <MovementsTable movements={snapshot.process_movements} />)}
  </div>
}

function FiltersForm({ filters, options, query, onChange, onQueryChange, onSearch, onClear }: { filters: Filters; options: Snapshot["filter_options"]; query: string; onChange: (key: FilterKey, value: string) => void; onQueryChange: (value: string) => void; onSearch: (value: string) => void; onClear: () => void }) {
  const [advancedOpen, setAdvancedOpen] = useState(() => FILTER_KEYS.some((key) => key !== "q" && filters[key]))
  const advancedFiltersId = "process-movements-advanced-filters"

  return <form className="react-process-movements__filters" aria-label="Filtros de andamentos" onSubmit={(event) => { event.preventDefault(); onSearch(query) }}>
    <div className="react-process-movements__search-row">
      <label className="react-process-movements__search">Busca<input value={query} placeholder="Processo, título, descrição ou responsável" onChange={(event) => onQueryChange(event.target.value)} /></label>
      <button className="react-process-movements__search-submit" type="submit">Buscar</button>
      <button className="react-process-movements__advanced-toggle" type="button" aria-expanded={advancedOpen} aria-controls={advancedFiltersId} onClick={() => setAdvancedOpen((open) => !open)}>Filtros avançados</button>
      <button className="react-process-movements__clear" type="button" onClick={onClear}>Limpar filtros</button>
    </div>
    <div className="react-process-movements__advanced-filters" id={advancedFiltersId} hidden={!advancedOpen}>
      <SelectFilter label="Fase" value={filters.phase_id} options={options.phases} blank="Todas" onChange={(value) => onChange("phase_id", value)} />
      <SelectFilter label="Status" value={filters.status} options={options.statuses} blank="Todos" onChange={(value) => onChange("status", value)} />
      <SelectFilter label="Tipo" value={filters.movement_type_id} options={options.movement_types} blank="Todos" onChange={(value) => onChange("movement_type_id", value)} />
      <SelectFilter label="Natureza" value={filters.nature} options={options.natures} blank="Todas" onChange={(value) => onChange("nature", value)} />
      <SelectFilter label="Impacto" value={filters.impact} options={options.impacts} blank="Todos" onChange={(value) => onChange("impact", value)} />
      <SelectFilter label="Origem" value={filters.origin} options={options.origins} blank="Todas" onChange={(value) => onChange("origin", value)} />
      <label>Período de<input type="date" value={filters.from} onChange={(event) => onChange("from", event.target.value)} /></label>
      <label>Período até<input type="date" value={filters.to} onChange={(event) => onChange("to", event.target.value)} /></label>
      <label>Responsável<input value={filters.responsible_name} onChange={(event) => onChange("responsible_name", event.target.value)} /></label>
      <SelectFilter label="Perícia" value={filters.exam_id} options={options.exams} blank="Todas" onChange={(value) => onChange("exam_id", value)} />
      <SelectFilter label="Situação administrativa" value={filters.administrative_situation} options={options.administrative_situations} blank="Todas" onChange={(value) => onChange("administrative_situation", value)} />
    </div>
  </form>
}

function SelectFilter({ label, value, options, blank, onChange }: { label: string; value: string; options: Option[]; blank: string; onChange: (value: string) => void }) {
  return <label>{label}<select value={value} onChange={(event) => onChange(event.target.value)}><option value="">{blank}</option>{options.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select></label>
}

function Reports({ reports }: { reports: Snapshot["reports"] }) {
  return <section className="react-process-movements__reports" aria-labelledby="process-movements-reports-heading">
    <h2 id="process-movements-reports-heading">Relatórios</h2>
    <div className="react-process-movements__report-grid">
      {Object.entries(reports).map(([key, report]) => <ReportCard report={report} key={key} />)}
    </div>
  </section>
}

function ReportCard({ report }: { report: ReportGroup }) {
  const max = Math.max(1, ...report.entries.map((entry) => entry.count))

  return <article className="react-process-movements__report-card">
    <div className="react-process-movements__report-head">
      <p>{report.title}</p>
      <strong>{report.total}</strong>
    </div>
    <div className="react-process-movements__report-bars">
      {report.entries.length ? report.entries.slice(0, 5).map((entry) => <div className="react-process-movements__report-row" key={entry.label}>
        <span>{entry.label}</span>
        <div className="react-process-movements__report-track" aria-hidden="true"><span style={{ width: `${Math.max(6, (entry.count / max) * 100)}%` }} /></div>
        <strong>{entry.count}</strong>
      </div>) : <p>Nenhum dado para exibir.</p>}
    </div>
  </article>
}

function Cards({ movements }: { movements: Movement[] }) {
  if (!movements.length) return <EmptyState />
  return <section className="react-process-movements__cards" aria-label="Listagem de andamentos">{movements.map((movement) => <article className="react-process-movements__card" aria-label={movement.display_title} key={movement.id}>
    <div className="react-process-movements__card-head">
      <div>
        <p className="react-process-movements__card-meta">{movement.event_date_label} · {movement.movement_type_name}</p>
        <h2><a href={movement.path}>{movement.display_title}</a></h2>
      </div>
      <span className="react-process-movements__badge">{movement.administrative_situation_label}</span>
    </div>
    {movement.description && <p className="react-process-movements__description">{movement.description}</p>}
    <dl>
      <div><dt>Processo</dt><dd>{movement.legal_case_path ? <a href={movement.legal_case_path}>{movement.process_number}</a> : movement.process_number}</dd></div>
      <div><dt>Cliente</dt><dd>{movement.client_name}</dd></div>
      <div><dt>Fase</dt><dd>{movement.phase_name}</dd></div>
      <div><dt>Status</dt><dd>{movement.status_label}</dd></div>
      <div><dt>Natureza</dt><dd>{movement.nature_label}</dd></div>
      <div><dt>Impacto</dt><dd>{movement.impact_label}</dd></div>
    </dl>
    <MovementActions movement={movement} />
  </article>)}</section>
}

function MovementsTable({ movements }: { movements: Movement[] }) {
  if (!movements.length) return <EmptyState />
  return <div className="react-process-movements__table-wrap"><table className="react-process-movements__table" aria-label="Listagem de andamentos processuais">
    <thead><tr><th>Processo</th><th>Cliente</th><th>Fase</th><th>Status</th><th>Tipo</th><th>Título</th><th>Data</th><th>Situação Adm.</th><th>Ações</th></tr></thead>
    <tbody>{movements.map((movement) => <tr key={movement.id}>
      <td>{movement.legal_case_path ? <a href={movement.legal_case_path}>{movement.process_number}</a> : movement.process_number}</td>
      <td>{movement.client_name}</td>
      <td>{movement.phase_name}</td>
      <td>{movement.status_label}</td>
      <td>{movement.movement_type_name}</td>
      <td><a href={movement.path}>{movement.display_title}</a></td>
      <td>{movement.event_date_label}</td>
      <td>{movement.administrative_situation_label}</td>
      <td><MovementActions movement={movement} compact /></td>
    </tr>)}</tbody>
  </table></div>
}

function MovementActions({ movement, compact = false }: { movement: Movement; compact?: boolean }) {
  const className = compact ? "react-process-movements__actions react-process-movements__actions--compact" : "react-process-movements__actions"

  return <div className={className}>
    <a href={movement.path} aria-label={`Ver andamento ${movement.display_title}`}>Ver</a>
    <a href={movement.edit_path} aria-label={`Editar andamento ${movement.display_title}`}>Editar</a>
  </div>
}

function LoadingSkeleton() {
  return <section className="react-process-movements__skeleton" aria-hidden="true"><span /><span /><span /></section>
}

function EmptyState() {
  return <section className="react-process-movements__empty"><h2>Nenhum andamento processual encontrado.</h2><p>Ajuste ou limpe os filtros para consultar outros andamentos.</p></section>
}
