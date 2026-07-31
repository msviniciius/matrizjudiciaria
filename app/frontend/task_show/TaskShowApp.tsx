import { useEffect, useState } from "react"
import "./taskShow.css"

type Snapshot = { task: { title: string; description: string | null; status_label: string; priority_label: string; due_date_label: string; responsible_name: string; process_number: string; client_name: string }; actions: { edit: string; index: string; delete: string; legal_case: string | null } }

export function TaskShowApp() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null)
  const [error, setError] = useState<string | null>(null)
  useEffect(() => { fetch(`${window.location.pathname}.json`, { headers: { Accept: "application/json" } }).then((response) => response.ok ? response.json() : Promise.reject(new Error("Não foi possível carregar a tarefa."))).then(setSnapshot).catch((reason: Error) => setError(reason.message)) }, [])

  if (error) return <section className="react-task-show react-task-show--loading"><div className="react-task-show__error" role="alert">{error}</div></section>
  if (!snapshot) return <section className="react-task-show react-task-show--loading" role="status">Carregando tarefa…</section>

  const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
  return <section className="react-task-show" aria-label="Detalhes da tarefa">
    <header className="react-task-show__header">
      <div><p className="react-task-show__eyebrow">Tarefa operacional</p><h1>{snapshot.task.title}</h1><p className="react-task-show__process">{snapshot.task.process_number} · {snapshot.task.client_name}</p></div>
      <div className="react-task-show__header-actions"><div className="react-task-show__actions"><a href={snapshot.actions.edit}>Editar tarefa</a></div><span className="react-task-show__badge">{snapshot.task.status_label}</span></div>
    </header>
    <div className="react-task-show__layout"><main className="react-task-show__main">
      <section className="react-task-show__section"><h2>Descrição</h2><p>{snapshot.task.description || "Nenhuma descrição cadastrada."}</p></section>
      <section className="react-task-show__section"><h2>Informações operacionais</h2><dl className="react-task-show__details"><div><dt>Data limite</dt><dd>{snapshot.task.due_date_label}</dd></div><div><dt>Prioridade</dt><dd>{snapshot.task.priority_label}</dd></div><div><dt>Responsável</dt><dd>{snapshot.task.responsible_name}</dd></div></dl></section>
    </main><aside className="react-task-show__rail"><section className="react-task-show__section">{snapshot.actions.legal_case && <a href={snapshot.actions.legal_case}>Abrir processo</a>}<form action={snapshot.actions.delete} method="post" onSubmit={(event) => { if (!window.confirm("Tem certeza que deseja excluir esta tarefa?")) event.preventDefault() }}><input type="hidden" name="_method" value="delete" />{csrfToken && <input type="hidden" name="authenticity_token" value={csrfToken} />}<button type="submit">Excluir tarefa</button></form><a href={snapshot.actions.index}>Voltar</a></section></aside></div>
  </section>
}
