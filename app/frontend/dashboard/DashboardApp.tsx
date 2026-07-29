import { useCallback, useEffect, useRef, useState } from "react"
import { PhaseBars } from "./components/PhaseBars"
import { StatusDonut, type DistributionItem } from "./components/StatusDonut"
import { ContextPanel } from "./components/ContextPanel"
import "./dashboard.css"

type QueueCase = { id: number; internal_number: string; path: string; responsible_name: string; update_responsible_path: string }
type Deadline = { id: number; title: string; legal_case_number: string; path: string }
type Snapshot = {
  meta: { office_name: string; unit_name?: string; syncable_count: number; new_imported_events_count: number }
  kpis: Record<string, { label: string; count: number; path: string; tone: string }>
  critical_queues: { without_responsible: QueueCase[]; without_next_action: QueueCase[]; overdue_deadlines_without_reason: Deadline[] }
  risk_queue: Record<string, { label: string; count: number; path: string }>
  feed: { title: string; origin: string; internal_number: string; date?: string; highlight: boolean; path: string }[]
  distribution: { phase: DistributionItem[]; status: DistributionItem[] }
  actions: { sync: string }
}

export function DashboardApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)
  const [selectedFilter, setSelectedFilter] = useState<DistributionItem | null>(null)
  const [isContextPanelOpen, setIsContextPanelOpen] = useState(false)
  const contextPanelTriggerRef = useRef<HTMLElement | null>(null)

  const selectFilter = (filter: DistributionItem) => {
    contextPanelTriggerRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null
    setSelectedFilter(filter)
    setIsContextPanelOpen(true)
  }
  const closeContextPanel = useCallback(() => setIsContextPanelOpen(false), [])

  const loadSnapshot = () => fetch("/painel.json", { headers: { Accept: "application/json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("Não foi possível carregar o painel.")))
    .then(setSnapshot)

  useEffect(() => {
    loadSnapshot()
      .catch((reason: Error) => setError(reason.message))
  }, [])

  const updateResponsible = async (path: string, responsibleName: string) => {
    const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
    const response = await fetch(path, { method: "PATCH", headers: { Accept: "application/json", "Content-Type": "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}) }, body: JSON.stringify({ responsible_name: responsibleName }) })
    const body = await response.json()
    if (!response.ok) throw new Error(body.error || "Não foi possível atualizar o responsável.")
    await loadSnapshot()
    setToast(body.message)
  }

  if (error) return <p className="react-dashboard__error" role="alert">{error}</p>
  if (!snapshot) return <p role="status">Carregando painel…</p>

  const queues = snapshot.critical_queues
  const nextAction = snapshot.feed.find((item) => item.highlight)

  return (
    <>
    <main className="react-dashboard" inert={isContextPanelOpen || undefined} aria-label="Painel operacional">
      <header className="react-dashboard__header">
        <div>
          <p className="react-dashboard__eyebrow">{snapshot.meta.office_name} · painel operacional</p>
          <h2>Central de comando</h2>
          <p>{snapshot.meta.unit_name ? `Unidade ${snapshot.meta.unit_name}` : "Todas as unidades"}</p>
        </div>
        <a className="react-dashboard__sync" href={snapshot.actions.sync}>Sincronizar andamentos <span>{snapshot.meta.new_imported_events_count}</span></a>
      </header>
      {toast && <p className="react-dashboard__toast" role="status">{toast}</p>}

      <section className="react-dashboard__kpis" aria-label="Indicadores operacionais">
        {Object.values(snapshot.kpis).map((kpi) => <a className={`react-dashboard__kpi react-dashboard__kpi--${kpi.tone}`} href={kpi.path} key={kpi.label} onClick={(event) => { event.preventDefault(); selectFilter(kpi) }}><span>{kpi.label}</span><strong>{kpi.count}</strong></a>)}
      </section>
      {selectedFilter && <p className="react-dashboard__filter-status" role="status">Filtro selecionado: {selectedFilter.label} ({selectedFilter.count} processos) <a href={selectedFilter.path}>Abrir processos filtrados</a></p>}
      {nextAction && <section className="react-dashboard__next-action" aria-labelledby="next-action-title">
        <div>
          <p className="react-dashboard__eyebrow">Prioridade do momento</p>
          <h3 id="next-action-title">Próxima ação</h3>
          <p>{nextAction.origin} · {nextAction.internal_number}</p>
        </div>
        <a href={nextAction.path}>{nextAction.title}<span>Ver processo →</span></a>
      </section>}

      <section className="react-dashboard__section">
        <h3>Fila de atenção</h3>
        <div className="react-dashboard__queues">
          <Queue title="Processos sem responsável" items={queues.without_responsible} empty="Todos os processos têm responsável definido." onUpdateResponsible={updateResponsible} />
          <Queue title="Sem próxima providência" items={queues.without_next_action} empty="Todos os processos têm próxima providência." />
          <Queue title="Prazos vencidos sem justificativa" items={queues.overdue_deadlines_without_reason} empty="Não há prazos vencidos sem justificativa." />
          <article className="react-dashboard__card"><h4>Central de risco</h4>{Object.values(snapshot.risk_queue).filter((risk) => risk.count > 0).map((risk) => <a href={risk.path} key={risk.label}>{risk.label}<strong>{risk.count}</strong></a>)}</article>
        </div>
      </section>

      <section className="react-dashboard__lower">
        <article className="react-dashboard__card"><h3>Últimos andamentos</h3>{snapshot.feed.length ? snapshot.feed.map((item) => <a className="react-dashboard__feed" href={item.path} key={`${item.origin}-${item.title}`}><span>{item.origin}</span><strong>{item.title}</strong><small>{item.internal_number}</small></a>) : <p>Nenhum andamento registrado.</p>}</article>
        <article className="react-dashboard__card"><h3>Distribuição por status</h3><StatusDonut items={snapshot.distribution.status} onSelect={selectFilter} selectedPath={selectedFilter?.path} /></article>
        <article className="react-dashboard__card"><h3>Distribuição por fase</h3><PhaseBars items={snapshot.distribution.phase} onSelect={selectFilter} selectedPath={selectedFilter?.path} /></article>
      </section>
    </main>
    {selectedFilter && isContextPanelOpen && <ContextPanel filter={selectedFilter} onClose={closeContextPanel} returnFocusTo={contextPanelTriggerRef.current} />}
    </>
  )
}

function Queue({ title, items, empty, onUpdateResponsible }: { title: string; items: Array<QueueCase | Deadline>; empty: string; onUpdateResponsible?: (path: string, value: string) => Promise<void> }) {
  return <article className="react-dashboard__card"><h4>{title}</h4>{items.length ? items.map((item) => "update_responsible_path" in item && onUpdateResponsible ? <ResponsibleItem item={item} onUpdate={onUpdateResponsible} key={item.id} /> : <a href={item.path} key={item.id}>{"internal_number" in item ? item.internal_number : item.title}<small>{"legal_case_number" in item ? item.legal_case_number : "Abrir processo"}</small></a>) : <p>{empty}</p>}</article>
}

function ResponsibleItem({ item, onUpdate }: { item: QueueCase; onUpdate: (path: string, value: string) => Promise<void> }) {
  const [value, setValue] = useState(item.responsible_name)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const submit = async (event: React.FormEvent) => { event.preventDefault(); setPending(true); setError(null); try { await onUpdate(item.update_responsible_path, value) } catch (reason) { setError(reason instanceof Error ? reason.message : "Não foi possível atualizar o responsável.") } finally { setPending(false) } }
  return <div className="react-dashboard__queue-item"><a href={item.path}>{item.internal_number}</a><form onSubmit={submit}><label>Responsável do processo {item.internal_number}<input value={value} onChange={(event) => setValue(event.target.value)} required /></label><button disabled={pending}>{pending ? "Salvando…" : "Salvar responsável"}</button></form>{error && <small role="alert">{error}</small>}</div>
}
