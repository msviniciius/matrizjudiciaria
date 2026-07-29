import { useEffect, useRef, useState } from "react"

type View = "cards" | "table"
type FilterKey = "q" | "phase" | "status" | "priority" | "responsible_name" | "deadline_state"

type Filters = Record<FilterKey, string>
type FilterOption = { label: string; value: string }
type LegalCase = {
  id: number
  path: string
  internal_number: string
  client_name: string
  legal_area_name: string
  status: string
  status_label: string
  phase: string
  priority: string
  responsible_name: string
  last_movement: string
  next_deadline_on: string | null
  next_deadline_label: string
  deadline_tone: string
  has_new_imported_events: boolean
}
type Snapshot = {
  meta: { office_name: string; unit_name?: string | null; total_count: number }
  filters: Filters
  filter_options: Record<FilterKey, FilterOption[]>
  legal_cases: LegalCase[]
  actions: { index: string; new: string; daily_closure: string }
}

const VIEW_KEY = "legal-cases-view"
const FILTER_KEYS: FilterKey[] = ["q", "phase", "status", "priority", "responsible_name", "deadline_state"]

function emptyFilters(): Filters {
  return { q: "", phase: "", status: "", priority: "", responsible_name: "", deadline_state: "" }
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
  return fetch(`/legal_cases.json?${filters}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function LegalCasesApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [filters, setFilters] = useState<Filters>(filtersFromLocation)
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

    fetchSnapshot(paramsFor(nextFilters), controller.signal)
      .then((nextSnapshot) => {
        if (requestRef.current.id !== id) return
        setSnapshot(nextSnapshot)
        setFilters(nextSnapshot.filters)
      })
      .catch((reason: unknown) => {
        if (requestRef.current.id !== id || (reason instanceof DOMException && reason.name === "AbortError")) return
        setError("Não foi possível atualizar os processos. Tente novamente.")
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

  const chooseView = (nextView: View) => {
    setView(nextView)
    sessionStorage.setItem(VIEW_KEY, nextView)
  }

  const retry = () => requestSnapshot(filters)

  return (
    <main aria-label="Processos">
      <header>
        <h1>Processos</h1>
        {snapshot && <p>{snapshot.meta.total_count} processo(s)</p>}
        <div aria-label="Visualização">
          <button type="button" aria-pressed={view === "cards"} onClick={() => chooseView("cards")}>Cartões</button>
          <button type="button" aria-pressed={view === "table"} onClick={() => chooseView("table")}>Tabela</button>
        </div>
      </header>

      {snapshot && <FiltersForm filters={filters} options={snapshot.filter_options} onChange={updateFilter} />}
      {isRefreshing && <p role="status">{snapshot ? "Atualizando processos…" : "Carregando processos…"}</p>}
      {error && <div role="alert"><p>{error}</p><button type="button" onClick={retry}>Tentar novamente</button></div>}
      {snapshot && (view === "cards" ? <Cards legalCases={snapshot.legal_cases} /> : <CasesTable legalCases={snapshot.legal_cases} />)}
    </main>
  )
}

function FiltersForm({ filters, options, onChange }: { filters: Filters; options: Snapshot["filter_options"]; onChange: (key: FilterKey, value: string) => void }) {
  return <form aria-label="Filtros de processos" onSubmit={(event) => event.preventDefault()}>
    <label>Busca<input value={filters.q} onChange={(event) => onChange("q", event.target.value)} /></label>
    <FilterSelect label="Fase" filterKey="phase" value={filters.phase} options={options.phase} onChange={onChange} />
    <FilterSelect label="Status" filterKey="status" value={filters.status} options={options.status} onChange={onChange} />
    <FilterSelect label="Prioridade" filterKey="priority" value={filters.priority} options={options.priority} onChange={onChange} />
    <label>Responsável<input value={filters.responsible_name} onChange={(event) => onChange("responsible_name", event.target.value)} /></label>
    <FilterSelect label="Situação do prazo" filterKey="deadline_state" value={filters.deadline_state} options={options.deadline_state} onChange={onChange} />
  </form>
}

function FilterSelect({ label, filterKey, value, options, onChange }: { label: string; filterKey: FilterKey; value: string; options: FilterOption[]; onChange: (key: FilterKey, value: string) => void }) {
  return <label>{label}<select value={value} onChange={(event) => onChange(filterKey, event.target.value)}><option value="">Todos</option>{options.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}</select></label>
}

function Cards({ legalCases }: { legalCases: LegalCase[] }) {
  if (!legalCases.length) return <p>Nenhum processo encontrado.</p>
  return <section aria-label="Listagem de processos">{legalCases.map((legalCase) => <article key={legalCase.id}>
    <a href={legalCase.path}><h2>{legalCase.internal_number}</h2></a>
    <p>{legalCase.client_name} · {legalCase.legal_area_name}</p>
    <p>{legalCase.status_label} · {legalCase.responsible_name}</p>
    <p>Próximo prazo: {legalCase.next_deadline_label}</p>
    <p>Último andamento: {legalCase.last_movement}</p>
    {legalCase.has_new_imported_events && <p>Novos andamentos importados</p>}
  </article>)}</section>
}

function CasesTable({ legalCases }: { legalCases: LegalCase[] }) {
  return <table aria-label="Listagem de processos">
    <thead><tr><th>Número interno</th><th>Cliente</th><th>Área</th><th>Status</th><th>Responsável</th><th>Próximo prazo</th><th>Último andamento</th></tr></thead>
    <tbody>{legalCases.length ? legalCases.map((legalCase) => <tr key={legalCase.id}>
      <td><a href={legalCase.path}>{legalCase.internal_number}</a></td><td>{legalCase.client_name}</td><td>{legalCase.legal_area_name}</td><td>{legalCase.status_label}</td><td>{legalCase.responsible_name}</td><td>{legalCase.next_deadline_label}</td><td>{legalCase.last_movement}</td>
    </tr>) : <tr><td colSpan={7}>Nenhum processo encontrado.</td></tr>}</tbody>
  </table>
}
