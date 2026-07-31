/// <reference path="../vite-env.d.ts" />

import { useEffect, useState } from "react"
import "./clientShow.css"

type Detail = { label: string; value: string }
type LinkedCase = {
  id: number
  internal_number: string
  phase_label: string
  status_label: string
  priority_label: string
  next_deadline_label: string
  responsible_name: string
  path: string
}
type Snapshot = {
  client: {
    id: number
    full_name: string
    cpf_cnpj: string
    phone: string
    email: string
    cadastro_pendente: boolean
    status_label: string
    legal_cases_count: number
    unit_name: string | null
  }
  identification: Detail[]
  contact: Detail[]
  address: Detail[]
  family: Detail[]
  notes: string
  gov: { present: boolean; masked: string; raw: string }
  legal_cases: LinkedCase[]
  actions: { index: string; edit: string; delete: string; new_legal_case: string }
}

function fetchSnapshot(): Promise<Snapshot> {
  return fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error("snapshot request failed")))
}

export function ClientShowApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const loadSnapshot = async () => {
    setError(null)
    setIsLoading(true)
    try {
      setSnapshot(await fetchSnapshot())
    } catch {
      setError("Não foi possível carregar os dados do cliente. Tente novamente.")
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadSnapshot()
  }, [])

  if (isLoading && !snapshot) {
    return <section className="react-client-show react-client-show--loading" aria-label="Dossiê do cliente"><p role="status">Carregando cliente…</p></section>
  }

  if (error && !snapshot) {
    return <section className="react-client-show react-client-show--loading" aria-label="Dossiê do cliente"><section className="react-client-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section></section>
  }

  if (!snapshot) return null

  return <section className="react-client-show" aria-label="Dossiê do cliente">
    <header className="react-client-show__header">
      <div>
        <p className="react-client-show__client">Dossiê do cliente</p>
        <h1>{snapshot.client.full_name}</h1>
        <p className="react-client-show__eyebrow">{snapshot.client.unit_name || "Operação jurídica"}</p>
        <p className="react-client-show__identifiers">{snapshot.client.cpf_cnpj}</p>
      </div>
      <div className="react-client-show__header-actions"><div className="react-client-show__actions"><a href={snapshot.actions.edit}>Editar cliente</a><a href={snapshot.actions.index}>Voltar</a></div><div className="react-client-show__badges" aria-label="Situação do cliente">
        <span className={`react-client-show__badge ${snapshot.client.cadastro_pendente ? "react-client-show__badge--pending" : "react-client-show__badge--complete"}`}>{snapshot.client.status_label}</span>
        <span className="react-client-show__badge">{snapshot.client.legal_cases_count} {snapshot.client.legal_cases_count === 1 ? "processo" : "processos"}</span>
      </div></div>
    </header>

    {error && <section className="react-client-show__error" role="alert"><p>{error}</p><button type="button" onClick={loadSnapshot}>Tentar novamente</button></section>}
    {isLoading && <p className="react-client-show__refreshing" role="status">Atualizando cliente…</p>}

    <div className="react-client-show__layout">
      <div className="react-client-show__main-column">
        <section className="react-client-show__summary" aria-labelledby="client-summary-heading">
          <h2 id="client-summary-heading">Resumo operacional</h2>
          <dl className="react-client-show__metrics">
            <div><dt>CPF/CNPJ</dt><dd>{snapshot.client.cpf_cnpj}</dd></div>
            <div><dt>Telefone</dt><dd>{snapshot.client.phone}</dd></div>
            <div><dt>E-mail</dt><dd>{snapshot.client.email}</dd></div>
            <div><dt>Processos vinculados</dt><dd>{snapshot.client.legal_cases_count}</dd></div>
          </dl>
        </section>

        <LinkedCasesSection cases={snapshot.legal_cases} />
        <TextSection title="Observações" value={snapshot.notes} emptyMessage="Sem observações cadastradas." />
        {snapshot.gov.present && <GovSection gov={snapshot.gov} />}
      </div>

      <aside className="react-client-show__rail" aria-label="Contexto do cliente">
        <DetailsSection title="Identificação" details={snapshot.identification} />
        <DetailsSection title="Contato" details={snapshot.contact} />
        <DetailsSection title="Endereço" details={snapshot.address} />
        <DetailsSection title="Filiação" details={snapshot.family} />
        <ClientShortcuts snapshot={snapshot} />
      </aside>
    </div>
  </section>
}

function DetailsSection({ title, details }: { title: string; details: Detail[] }) {
  return <section className="react-client-show__case-data" aria-labelledby={`client-show-${title}`}>
    <h2 id={`client-show-${title}`}>{title}</h2>
    <dl>
      {details.map((detail) => <div key={detail.label}><dt>{detail.label}</dt><dd>{detail.value}</dd></div>)}
    </dl>
  </section>
}

function LinkedCasesSection({ cases }: { cases: LinkedCase[] }) {
  return <section className="react-client-show__timeline" aria-labelledby="client-cases-heading">
    <h2 id="client-cases-heading">Processos vinculados</h2>
    {cases.length ? <ol>
      {cases.map((legalCase) => <li className="react-client-show__timeline-item" key={legalCase.id}>
        <p className="react-client-show__timeline-meta">{legalCase.phase_label} · {legalCase.status_label} · Prioridade {legalCase.priority_label}</p>
        <h3><a href={legalCase.path}>{legalCase.internal_number}</a></h3>
        <p>Próximo prazo: {legalCase.next_deadline_label}</p>
        <p>Responsável: {legalCase.responsible_name}</p>
      </li>)}
    </ol> : <p>Este cliente ainda não possui processos cadastrados.</p>}
  </section>
}

function TextSection({ title, value, emptyMessage }: { title: string; value: string; emptyMessage: string }) {
  return <section className="react-client-show__text-section" aria-labelledby={`client-show-${title}`}>
    <h2 id={`client-show-${title}`}>{title}</h2>
    {value.trim() ? <MultilineText value={value} /> : <p>{emptyMessage}</p>}
  </section>
}

function GovSection({ gov }: { gov: Snapshot["gov"] }) {
  return <section className="react-client-show__text-section" aria-labelledby="client-gov-heading">
    <h2 id="client-gov-heading">Dados GOV</h2>
    <MultilineText value={gov.masked} />
    <details className="react-client-show__details">
      <summary>Mostrar dados completos</summary>
      <MultilineText value={gov.raw} />
    </details>
  </section>
}

function MultilineText({ value }: { value: string }) {
  return <div className="react-client-show__longtext">{value.split("\n").map((line, index) => <p key={`${line}-${index}`}>{line}</p>)}</div>
}

function ClientShortcuts({ snapshot }: { snapshot: Snapshot }) {
  const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
  const deleteMessage = snapshot.client.legal_cases_count > 0
    ? `Este cliente possui ${snapshot.client.legal_cases_count} ${snapshot.client.legal_cases_count === 1 ? "processo vinculado" : "processos vinculados"}. Deseja continuar com a exclusão?`
    : "Excluir este cliente?"

  return <nav className="react-client-show__shortcuts" aria-label="Atalhos do cliente">
    <a href={snapshot.actions.new_legal_case}>Novo processo</a>
    <form action={snapshot.actions.delete} method="post" onSubmit={(event) => { if (!window.confirm(deleteMessage)) event.preventDefault() }}>
      <input type="hidden" name="_method" value="delete" />
      {csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}
      <button type="submit">Excluir cliente</button>
    </form>
  </nav>
}
