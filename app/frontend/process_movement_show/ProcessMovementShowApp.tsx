/// <reference path="../vite-env.d.ts" />

import { useEffect, useState } from "react"
import "./processMovementShow.css"

type Detail = { label: string; value: string }
type Audit = {
  id: number
  action: string
  action_label: string
  created_at: string | null
  created_at_label: string
  justification: string
  changed_fields_count: number
  changed_fields: string[]
}
type Snapshot = {
  movement: {
    id: number
    display_title: string
    event_date: string | null
    event_date_label: string
    phase_name: string
    movement_type_name: string
    movement_template_name: string
    nature_label: string
    impact_label: string
    origin_label: string
    administrative_situation_label: string
    active: boolean
  }
  legal_case: {
    id: number
    internal_number: string
    external_number: string | null
    client_name: string
    status_label: string
    phase_label: string
    responsible_name: string
    path: string
    client_path: string | null
  }
  details: Detail[]
  automation: {
    updates_phase: boolean
    next_phase_name: string
    creates_task: boolean
    creates_deadline: boolean
  }
  description: string
  audits: Audit[]
  actions: { index: string; edit: string; delete: string; legal_case: string }
}

function fetchSnapshot(): Promise<Snapshot> {
  return fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function ProcessMovementShowApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const loadSnapshot = async () => {
    setError(null)
    setIsLoading(true)
    try {
      setSnapshot(await fetchSnapshot())
    } catch {
      setError("Não foi possível carregar os dados do andamento. Tente novamente.")
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadSnapshot()
  }, [])

  if (isLoading && !snapshot) {
    return <section className="react-process-movement-show react-process-movement-show--loading" aria-label="Detalhe do andamento"><p role="status">Carregando andamento...</p></section>
  }

  if (error && !snapshot) {
    return <section className="react-process-movement-show react-process-movement-show--loading" aria-label="Detalhe do andamento"><ErrorNotice message={error} onRetry={loadSnapshot} /></section>
  }

  if (!snapshot) return null

  return <section className="react-process-movement-show" aria-label="Detalhe do andamento">
    <header className="react-process-movement-show__header">
      <div>
        <p className="react-process-movement-show__client">{snapshot.legal_case.client_name}</p>
        <h1>{snapshot.movement.display_title}</h1>
        <p className="react-process-movement-show__eyebrow">Processo {snapshot.legal_case.internal_number}</p>
        <p className="react-process-movement-show__identifiers">{snapshot.legal_case.external_number ? `CNJ: ${snapshot.legal_case.external_number}` : "Sem número CNJ"}</p>
      </div>
      <div className="react-process-movement-show__header-actions"><div className="react-process-movement-show__actions"><a href={snapshot.actions.edit}>Editar andamento</a><a href={snapshot.actions.index}>Voltar</a></div><div className="react-process-movement-show__badges" aria-label="Situação do andamento">
        <span className="react-process-movement-show__badge">{snapshot.movement.phase_name}</span>
        <span className="react-process-movement-show__badge">{snapshot.movement.administrative_situation_label}</span>
        <span className={snapshot.movement.active ? "react-process-movement-show__badge react-process-movement-show__badge--active" : "react-process-movement-show__badge react-process-movement-show__badge--inactive"}>{snapshot.movement.active ? "Ativo" : "Inativo"}</span>
      </div></div>
    </header>

    {error && <ErrorNotice message={error} onRetry={loadSnapshot} />}
    {isLoading && <p className="react-process-movement-show__refreshing" role="status">Atualizando andamento...</p>}

    <div className="react-process-movement-show__layout">
      <div className="react-process-movement-show__main-column">
        <section className="react-process-movement-show__summary" aria-labelledby="movement-summary-heading">
          <h2 id="movement-summary-heading">Resumo operacional</h2>
          <dl className="react-process-movement-show__metrics">
            <div><dt>Data</dt><dd>{snapshot.movement.event_date_label}</dd></div>
            <div><dt>Tipo</dt><dd>{snapshot.movement.movement_type_name}</dd></div>
            <div><dt>Natureza</dt><dd>{snapshot.movement.nature_label}</dd></div>
            <div><dt>Impacto</dt><dd>{snapshot.movement.impact_label}</dd></div>
          </dl>
        </section>

        <TextSection headingId="process-movement-description-heading" title="Descrição complementar" value={snapshot.description} emptyMessage="Sem descrição complementar cadastrada." />
        <AutomationSection automation={snapshot.automation} />
        <AuditSection audits={snapshot.audits} />
      </div>

      <aside className="react-process-movement-show__rail" aria-label="Contexto do andamento">
        <section className="react-process-movement-show__case-data" aria-labelledby="movement-case-heading">
          <h2 id="movement-case-heading">Processo vinculado</h2>
          <dl>
            <div><dt>Processo</dt><dd><a href={snapshot.legal_case.path}>{snapshot.legal_case.internal_number}</a></dd></div>
            <div><dt>Cliente</dt><dd>{snapshot.legal_case.client_path ? <a href={snapshot.legal_case.client_path}>{snapshot.legal_case.client_name}</a> : snapshot.legal_case.client_name}</dd></div>
            <div><dt>Fase atual</dt><dd>{snapshot.legal_case.phase_label}</dd></div>
            <div><dt>Status</dt><dd>{snapshot.legal_case.status_label}</dd></div>
            <div><dt>Responsável</dt><dd>{snapshot.legal_case.responsible_name}</dd></div>
          </dl>
        </section>
        <DetailsSection details={snapshot.details} />
        <MovementShortcuts snapshot={snapshot} />
      </aside>
    </div>
  </section>
}

function ErrorNotice({ message, onRetry }: { message: string; onRetry: () => void }) {
  return <section className="react-process-movement-show__error" role="alert"><p>{message}</p><button type="button" onClick={onRetry}>Tentar novamente</button></section>
}

function DetailsSection({ details }: { details: Detail[] }) {
  return <section className="react-process-movement-show__case-data" aria-labelledby="movement-details-heading">
    <h2 id="movement-details-heading">Detalhes</h2>
    <dl>
      {details.map((detail) => <div key={detail.label}><dt>{detail.label}</dt><dd>{detail.value}</dd></div>)}
    </dl>
  </section>
}

function TextSection({ headingId, title, value, emptyMessage }: { headingId: string; title: string; value: string; emptyMessage: string }) {
  return <section className="react-process-movement-show__text-section" aria-labelledby={headingId}>
    <h2 id={headingId}>{title}</h2>
    {value.trim() ? <MultilineText value={value} /> : <p>{emptyMessage}</p>}
  </section>
}

function MultilineText({ value }: { value: string }) {
  return <div className="react-process-movement-show__longtext">{value.split("\n").map((line, index) => <p key={`${line}-${index}`}>{line}</p>)}</div>
}

function AutomationSection({ automation }: { automation: Snapshot["automation"] }) {
  return <section className="react-process-movement-show__automation" aria-labelledby="movement-automation-heading">
    <h2 id="movement-automation-heading">Automações</h2>
    <dl className="react-process-movement-show__metrics">
      <div><dt>Atualiza fase</dt><dd>{automation.updates_phase ? "Sim" : "Não"}</dd></div>
      <div><dt>Próxima fase</dt><dd>{automation.next_phase_name}</dd></div>
      <div><dt>Cria tarefa</dt><dd>{automation.creates_task ? "Sim" : "Não"}</dd></div>
      <div><dt>Cria prazo</dt><dd>{automation.creates_deadline ? "Sim" : "Não"}</dd></div>
    </dl>
  </section>
}

function AuditSection({ audits }: { audits: Audit[] }) {
  return <section className="react-process-movement-show__timeline" aria-labelledby="movement-audit-heading">
    <h2 id="movement-audit-heading">Auditoria</h2>
    {audits.length ? <ol>
      {audits.map((audit) => <li className="react-process-movement-show__timeline-item" key={audit.id}>
        <p className="react-process-movement-show__timeline-meta">{audit.created_at_label}</p>
        <h3>{audit.action_label}</h3>
        <p>Justificativa: {audit.justification}</p>
        {audit.changed_fields_count > 0 && <p>Campos alterados: {audit.changed_fields.join(", ")}</p>}
      </li>)}
    </ol> : <p>Sem registros de auditoria.</p>}
  </section>
}

function MovementShortcuts({ snapshot }: { snapshot: Snapshot }) {
  const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""

  return <nav className="react-process-movement-show__shortcuts" aria-label="Atalhos do andamento">
    <a href={snapshot.actions.legal_case}>Abrir processo</a>
    <form action={snapshot.actions.delete} method="post" onSubmit={(event) => { if (!window.confirm("Confirma a exclusão deste andamento?")) event.preventDefault() }}>
      <input type="hidden" name="_method" value="delete" />
      {csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}
      <button type="submit">Excluir andamento</button>
    </form>
  </nav>
}
