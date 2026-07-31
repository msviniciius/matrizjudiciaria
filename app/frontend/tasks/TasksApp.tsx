import { useEffect, useRef, useState } from "react"
import "./tasks.css"

type View = "cards" | "table"
type FilterKey = "q" | "status" | "priority" | "responsible_name" | "due_state"
type Option = { value: string; label: string }
type Filters = Record<FilterKey, string>
type Task = { id: number; path: string; edit_path: string; delete_path: string; legal_case_path: string; process_number: string; client_name: string; title: string; description: string; status: string; status_label: string; priority: string | null; priority_label: string; due_date_label: string; due_state: string; due_state_label: string; responsible_name: string }
type Snapshot = { meta: { office_name: string; unit_name?: string | null; total_count: number }; filters: Filters; filter_options: { statuses: Option[]; priorities: Option[]; due_states: Option[] }; tasks: Task[]; actions: { index: string; new: string } }

const VIEW_KEY = "tasks-view"
const FILTER_KEYS: FilterKey[] = ["q", "status", "priority", "responsible_name", "due_state"]
const emptyFilters = (): Filters => ({ q: "", status: "", priority: "", responsible_name: "", due_state: "" })
const filtersFromLocation = (): Filters => { const params = new URLSearchParams(window.location.search); return FILTER_KEYS.reduce((result, key) => ({ ...result, [key]: params.get(key) || "" }), emptyFilters()) }
const paramsFor = (filters: Filters) => { const params = new URLSearchParams(); FILTER_KEYS.forEach((key) => filters[key] && params.set(key, filters[key])); return params }
const savedView = (): View => sessionStorage.getItem(VIEW_KEY) === "table" ? "table" : "cards"
const fetchSnapshot = (params: URLSearchParams, signal?: AbortSignal): Promise<Snapshot> => fetch(`/tasks.json?${params}`, { headers: { Accept: "application/json" }, signal }).then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))

export function TasksApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [filters, setFilters] = useState<Filters>(filtersFromLocation)
  const [draftQuery, setDraftQuery] = useState(() => filtersFromLocation().q)
  const [view, setView] = useState<View>(savedView)
  const [error, setError] = useState<string | null>(null)
  const [refreshing, setRefreshing] = useState(true)
  const request = useRef({ id: 0, controller: null as AbortController | null })

  const load = (nextFilters: Filters) => {
    request.current.controller?.abort()
    const controller = new AbortController(); const id = request.current.id + 1
    request.current = { id, controller }; setError(null); setRefreshing(true)
    fetchSnapshot(paramsFor(nextFilters), controller.signal).then((next) => {
      if (request.current.id !== id) return
      setSnapshot(next); setFilters(next.filters); setDraftQuery((current) => current === nextFilters.q ? next.filters.q : current)
    }).catch((reason: unknown) => {
      if (request.current.id !== id || (reason instanceof DOMException && reason.name === "AbortError")) return
      setError("Não foi possível atualizar as tarefas. Tente novamente.")
    }).finally(() => { if (request.current.id === id) setRefreshing(false) })
  }

  useEffect(() => { load(filters); return () => request.current.controller?.abort() }, [])
  const updateFilter = (key: FilterKey, value: string) => { const next = { ...filters, [key]: value }; window.history.replaceState({}, "", `${window.location.pathname}?${paramsFor(next)}`); setFilters(next); load(next) }
  const clearFilters = () => { const next = emptyFilters(); window.history.replaceState({}, "", window.location.pathname); setFilters(next); setDraftQuery(""); load(next) }
  const chooseView = (next: View) => { setView(next); sessionStorage.setItem(VIEW_KEY, next) }

  return <div className="react-tasks" aria-label="Tarefas">
    <header className="react-tasks__header"><div><p className="react-tasks__eyebrow">{snapshot?.meta.unit_name || snapshot?.meta.office_name || "Operação jurídica"}</p><h1>Tarefas</h1>{snapshot && <p className="react-tasks__count" role="status">{snapshot.meta.total_count} tarefa(s)</p>}</div><div className="react-tasks__header-actions">{snapshot?.actions.new && <a className="react-tasks__new" href={snapshot.actions.new}>Nova tarefa</a>}<div className="react-tasks__view-switch" aria-label="Visualização"><button type="button" aria-pressed={view === "cards"} onClick={() => chooseView("cards")}>Cartões</button><button type="button" aria-pressed={view === "table"} onClick={() => chooseView("table")}>Tabela</button></div></div></header>
    {snapshot && <FiltersForm filters={filters} options={snapshot.filter_options} query={draftQuery} onQueryChange={setDraftQuery} onChange={updateFilter} onSearch={(query) => updateFilter("q", query)} onClear={clearFilters} />}
    {refreshing && <div className="react-tasks__loading" role="status"><span aria-hidden="true" className="react-tasks__loading-mark" />{snapshot ? "Atualizando tarefas..." : "Carregando tarefas..."}</div>}
    {!snapshot && refreshing && <LoadingSkeleton />}{error && <section className="react-tasks__error" role="alert"><p>{error}</p><button type="button" onClick={() => load(filters)}>Tentar novamente</button></section>}
    {snapshot && (view === "cards" ? <Cards tasks={snapshot.tasks} /> : <TasksTable tasks={snapshot.tasks} />)}
  </div>
}

function FiltersForm({ filters, options, query, onQueryChange, onChange, onSearch, onClear }: { filters: Filters; options: Snapshot["filter_options"]; query: string; onQueryChange: (value: string) => void; onChange: (key: FilterKey, value: string) => void; onSearch: (value: string) => void; onClear: () => void }) {
  const [open, setOpen] = useState(false); const id = "tasks-advanced-filters"
  return <form className="react-tasks__filters" aria-label="Filtros de tarefas" onSubmit={(event) => { event.preventDefault(); onSearch(query) }}><div className="react-tasks__search-row"><label>Busca<input value={query} placeholder="Processo, título ou responsável" onChange={(event) => onQueryChange(event.target.value)} /></label><button className="react-tasks__search-submit" type="submit">Buscar</button><button className="react-tasks__advanced-toggle" type="button" aria-expanded={open} aria-controls={id} onClick={() => setOpen((value) => !value)}>Filtros avançados</button><button className="react-tasks__clear" type="button" onClick={onClear}>Limpar filtros</button></div><div className="react-tasks__advanced-filters" id={id} hidden={!open}><SelectFilter label="Status" value={filters.status} options={options.statuses} blank="Todos" onChange={(value) => onChange("status", value)} /><SelectFilter label="Prioridade" value={filters.priority} options={options.priorities} blank="Todas" onChange={(value) => onChange("priority", value)} /><label>Responsável<input value={filters.responsible_name} onChange={(event) => onChange("responsible_name", event.target.value)} /></label><SelectFilter label="Situação da data" value={filters.due_state} options={options.due_states} blank="Todas" onChange={(value) => onChange("due_state", value)} /></div></form>
}
function SelectFilter({ label, value, options, blank, onChange }: { label: string; value: string; options: Option[]; blank: string; onChange: (value: string) => void }) { return <label>{label}<select value={value} onChange={(event) => onChange(event.target.value)}><option value="">{blank}</option>{options.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select></label> }
function Cards({ tasks }: { tasks: Task[] }) { if (!tasks.length) return <EmptyState />; return <section className="react-tasks__cards" aria-label="Listagem de tarefas">{tasks.map((task) => <article className="react-tasks__card" aria-label={task.title} key={task.id}><div className="react-tasks__card-head"><h2><a href={task.path}>{task.title}</a></h2><span className={`react-tasks__badge react-tasks__badge--${task.due_state}`}>{task.due_state_label}</span></div><p className="react-tasks__document"><a href={task.legal_case_path}>{task.process_number}</a> · {task.client_name}</p><dl><div><dt>Data limite</dt><dd>{task.due_date_label}</dd></div><div><dt>Status</dt><dd>{task.status_label}</dd></div><div><dt>Prioridade</dt><dd>{task.priority_label}</dd></div><div><dt>Responsável</dt><dd>{task.responsible_name}</dd></div></dl><TaskActions task={task} /></article>)}</section> }
function TasksTable({ tasks }: { tasks: Task[] }) { if (!tasks.length) return <EmptyState />; return <div className="react-tasks__table-wrap"><table className="react-tasks__table" aria-label="Listagem de tarefas"><thead><tr><th>Processo</th><th>Tarefa</th><th>Data limite</th><th>Status</th><th>Prioridade</th><th>Responsável</th><th>Ações</th></tr></thead><tbody>{tasks.map((task) => <tr key={task.id}><td><a href={task.legal_case_path}>{task.process_number}</a></td><td><a href={task.path}>{task.title}</a></td><td>{task.due_date_label}</td><td><span className={`react-tasks__badge react-tasks__badge--${task.due_state}`}>{task.status_label}</span></td><td>{task.priority_label}</td><td>{task.responsible_name}</td><td><TaskActions task={task} compact /></td></tr>)}</tbody></table></div> }
function TaskActions({ task, compact = false }: { task: Task; compact?: boolean }) { const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""; return <div className={compact ? "react-tasks__actions react-tasks__actions--compact" : "react-tasks__actions"}><a href={task.edit_path} aria-label={`Editar tarefa ${task.title}`}>Editar</a><form action={task.delete_path} method="post" onSubmit={(event) => { if (!window.confirm("Excluir esta tarefa?")) event.preventDefault() }}><input type="hidden" name="_method" value="delete" />{token && <input type="hidden" name="authenticity_token" value={token} />}<button type="submit" aria-label={`Excluir tarefa ${task.title}`}>Excluir</button></form></div> }
function LoadingSkeleton() { return <section className="react-tasks__skeleton" aria-hidden="true"><span /><span /><span /></section> }
function EmptyState() { return <section className="react-tasks__empty"><h2>Nenhuma tarefa encontrada para estes filtros.</h2><p>Ajuste ou limpe os filtros para consultar outras tarefas.</p></section> }
