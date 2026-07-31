import { useEffect, useRef, useState } from "react"
import "./clients.css"

type View = "cards" | "table"
type FilterKey = "q" | "cadastro_pendente" | "city"
type Filters = Record<FilterKey, string>
type Client = {
  id: number
  path: string
  edit_path: string
  delete_path: string
  full_name: string
  cpf_cnpj: string
  phone: string
  email: string
  city: string
  cadastro_pendente: boolean
  status_label: string
  legal_cases_count: number
  processes_path: string
}
type Snapshot = {
  meta: { office_name: string; unit_name?: string | null; total_count: number }
  filters: Filters
  clients: Client[]
  actions: { index: string; new: string }
}

const VIEW_KEY = "clients-view"
const FILTER_KEYS: FilterKey[] = ["q", "cadastro_pendente", "city"]

function emptyFilters(): Filters {
  return { q: "", cadastro_pendente: "", city: "" }
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
  return fetch(`/clients.json?${filters}`, { headers: { Accept: "application/json" }, signal })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function ClientsApp() {
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
        setError("Não foi possível atualizar os clientes. Tente novamente.")
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

  return <div className="react-clients" aria-label="Clientes">
    <header className="react-clients__header">
      <div>
        <p className="react-clients__eyebrow">{snapshot?.meta.unit_name || snapshot?.meta.office_name || "Operação jurídica"}</p>
        <h1>Clientes</h1>
        {snapshot && <p className="react-clients__count" role="status">{snapshot.meta.total_count} cliente(s)</p>}
      </div>
      <div className="react-clients__header-actions">
        {snapshot?.actions.new && <a className="react-clients__new" href={snapshot.actions.new}>Novo cliente</a>}
        <div className="react-clients__view-switch" aria-label="Visualização">
        <button type="button" aria-pressed={view === "cards"} onClick={() => chooseView("cards")}>Cartões</button>
        <button type="button" aria-pressed={view === "table"} onClick={() => chooseView("table")}>Tabela</button>
        </div>
      </div>
    </header>

    {snapshot && <FiltersForm filters={filters} query={draftQuery} onChange={updateFilter} onQueryChange={setDraftQuery} onSearch={(query) => updateFilter("q", query)} onClear={clearFilters} />}
    {isRefreshing && <div className="react-clients__loading" role="status"><span aria-hidden="true" className="react-clients__loading-mark" />{snapshot ? "Atualizando clientes…" : "Carregando clientes…"}</div>}
    {!snapshot && isRefreshing && <LoadingSkeleton />}
    {error && <section className="react-clients__error" role="alert"><p>{error}</p><button type="button" onClick={() => requestSnapshot(filters)}>Tentar novamente</button></section>}
    {snapshot && (view === "cards" ? <Cards clients={snapshot.clients} /> : <ClientsTable clients={snapshot.clients} />)}
  </div>
}

function FiltersForm({ filters, query, onChange, onQueryChange, onSearch, onClear }: { filters: Filters; query: string; onChange: (key: FilterKey, value: string) => void; onQueryChange: (value: string) => void; onSearch: (value: string) => void; onClear: () => void }) {
  const [advancedOpen, setAdvancedOpen] = useState(false)
  const advancedFiltersId = "clients-advanced-filters"

  return <form className="react-clients__filters" aria-label="Filtros de clientes" onSubmit={(event) => { event.preventDefault(); onSearch(query) }}>
    <div className="react-clients__search-row">
      <label className="react-clients__search">Busca<input value={query} placeholder="Nome, CPF/CNPJ, telefone ou e-mail" onChange={(event) => onQueryChange(event.target.value)} /></label>
      <button className="react-clients__search-submit" type="submit">Buscar</button>
      <button className="react-clients__advanced-toggle" type="button" aria-expanded={advancedOpen} aria-controls={advancedFiltersId} onClick={() => setAdvancedOpen((open) => !open)}>Filtros avançados</button>
      <button className="react-clients__clear" type="button" onClick={onClear}>Limpar filtros</button>
    </div>
    <div className="react-clients__advanced-filters" id={advancedFiltersId} hidden={!advancedOpen}>
      <label>Status do cadastro<select value={filters.cadastro_pendente} onChange={(event) => onChange("cadastro_pendente", event.target.value)}><option value="">Todos</option><option value="true">Pendente</option><option value="false">Completo</option></select></label>
      <label>Cidade<input value={filters.city} placeholder="Cidade do cliente" onChange={(event) => onChange("city", event.target.value)} /></label>
    </div>
  </form>
}

function Cards({ clients }: { clients: Client[] }) {
  if (!clients.length) return <EmptyState />
  return <section className="react-clients__cards" aria-label="Listagem de clientes">{clients.map((client) => <article className="react-clients__card" aria-label={client.full_name} key={client.id}>
    <div className="react-clients__card-head"><h2><a href={client.path}>{client.full_name}</a></h2><span className={`react-clients__badge ${client.cadastro_pendente ? "react-clients__badge--pending" : "react-clients__badge--complete"}`}>{client.status_label}</span></div>
    <p className="react-clients__document">{client.cpf_cnpj || "CPF/CNPJ não informado"}</p>
    <dl><div><dt>Telefone</dt><dd>{client.phone || "Não informado"}</dd></div><div><dt>E-mail</dt><dd>{client.email || "Não informado"}</dd></div><div><dt>Cidade</dt><dd>{client.city || "Não informada"}</dd></div><div><dt>Processos</dt><dd>{client.legal_cases_count} {client.legal_cases_count === 1 ? "processo" : "processos"}</dd></div></dl>
    <ClientActions client={client} />
  </article>)}</section>
}

function ClientsTable({ clients }: { clients: Client[] }) {
  if (!clients.length) return <EmptyState />
  return <div className="react-clients__table-wrap"><table className="react-clients__table" aria-label="Listagem de clientes">
    <thead><tr><th>Nome</th><th>CPF/CNPJ</th><th>Telefone</th><th>E-mail</th><th>Cidade</th><th>Status</th><th>Processos</th><th>Ações</th></tr></thead>
    <tbody>{clients.map((client) => <tr key={client.id}><td><a href={client.path}>{client.full_name}</a></td><td>{client.cpf_cnpj || "-"}</td><td>{client.phone || "-"}</td><td>{client.email || "-"}</td><td>{client.city || "-"}</td><td><span className={`react-clients__badge ${client.cadastro_pendente ? "react-clients__badge--pending" : "react-clients__badge--complete"}`}>{client.status_label}</span></td><td>{client.legal_cases_count}</td><td><ClientActions client={client} compact /></td></tr>)}</tbody>
  </table></div>
}

function ClientActions({ client, compact = false }: { client: Client; compact?: boolean }) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
  const className = compact ? "react-clients__actions react-clients__actions--compact" : "react-clients__actions"
  const confirmationMessage = client.legal_cases_count > 0
    ? `Este cliente possui ${client.legal_cases_count} ${client.legal_cases_count === 1 ? "processo vinculado" : "processos vinculados"}. Deseja continuar com a exclusão?`
    : "Excluir este cliente?"
  return <div className={className}>
    <a href={client.edit_path} aria-label={`Editar cliente ${client.full_name}`}>Editar</a>
    <form action={client.delete_path} method="post" onSubmit={(event) => { if (!window.confirm(confirmationMessage)) event.preventDefault() }}>
      <input type="hidden" name="_method" value="delete" />
      {csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}
      <button type="submit" aria-label={`Excluir cliente ${client.full_name}`}>Excluir</button>
    </form>
  </div>
}

function LoadingSkeleton() {
  return <section className="react-clients__skeleton" aria-hidden="true"><span /><span /><span /></section>
}

function EmptyState() {
  return <section className="react-clients__empty"><h2>Nenhum cliente encontrado para estes filtros.</h2><p>Ajuste ou limpe os filtros para consultar outros clientes.</p></section>
}
