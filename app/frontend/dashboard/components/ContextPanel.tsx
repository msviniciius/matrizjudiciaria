import { useEffect, useRef, useState } from "react"
import type { ContextCase, DistributionItem } from "./StatusDonut"

type ContextPanelProps = {
  filter: DistributionItem
  onClose: () => void
  onUpdateResponsible: (path: string, value: string) => Promise<void>
  onUpdateNextAction: (path: string, value: string) => Promise<void>
  returnFocusTo: HTMLElement | null
}

export function ContextPanel({ filter, onClose, onUpdateResponsible, onUpdateNextAction, returnFocusTo }: ContextPanelProps) {
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const dialogRef = useRef<HTMLElement>(null)

  useEffect(() => {
    closeButtonRef.current?.focus()
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose()
      if (event.key !== "Tab") return

      const focusableElements = Array.from(dialogRef.current?.querySelectorAll<HTMLElement>("a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])") || [])
      if (!focusableElements.length) return

      const activeIndex = focusableElements.indexOf(document.activeElement as HTMLElement)
      const nextFocus = event.shiftKey
        ? activeIndex <= 0 ? focusableElements.at(-1) : undefined
        : activeIndex === -1 || activeIndex === focusableElements.length - 1 ? focusableElements[0] : undefined

      if (nextFocus) {
        event.preventDefault()
        nextFocus.focus()
      }
    }
    document.addEventListener("keydown", handleKeyDown)
    return () => {
      document.removeEventListener("keydown", handleKeyDown)
      returnFocusTo?.focus()
    }
  }, [onClose, returnFocusTo])

  return <div className="react-dashboard__panel-overlay" onMouseDown={(event) => {
    if (event.target === event.currentTarget) onClose()
  }}>
    <aside aria-labelledby="context-panel-title" aria-modal="true" className="react-dashboard__context-panel" ref={dialogRef} role="dialog">
      <div className="react-dashboard__context-panel-header">
        <p className="react-dashboard__eyebrow">Filtro selecionado</p>
        <button aria-label="Fechar painel" onClick={onClose} ref={closeButtonRef} type="button">Fechar</button>
      </div>
      <h3 id="context-panel-title">Detalhes do filtro: {filter.label}</h3>
      <p className="react-dashboard__context-panel-count">{filter.count} processos</p>
      <section className="react-dashboard__context-items" aria-label="Processos filtrados">
        {filter.items?.length
          ? filter.items.map((item) => <ContextCaseItem item={item} key={item.id} onClose={onClose} onUpdateResponsible={onUpdateResponsible} onUpdateNextAction={onUpdateNextAction} />)
          : <p>Nenhum processo disponível nesta prévia.</p>}
      </section>
      <a className="react-dashboard__context-panel-link" href={filter.path}>Ver processos filtrados</a>
    </aside>
  </div>
}

function ContextCaseItem({ item, onClose, onUpdateResponsible, onUpdateNextAction }: { item: ContextCase; onClose: () => void; onUpdateResponsible: (path: string, value: string) => Promise<void>; onUpdateNextAction: (path: string, value: string) => Promise<void> }) {
  const [responsibleName, setResponsibleName] = useState(item.responsible_name)
  const [nextAction, setNextAction] = useState(item.next_action)
  const [pendingAction, setPendingAction] = useState<"responsible" | "next-action" | null>(null)
  const [error, setError] = useState<string | null>(null)

  const submit = async (event: React.FormEvent, action: "responsible" | "next-action") => {
    event.preventDefault()
    setPendingAction(action)
    setError(null)
    try {
      if (action === "responsible") {
        await onUpdateResponsible(item.update_responsible_path, responsibleName)
      } else {
        await onUpdateNextAction(item.update_next_action_path, nextAction)
      }
      onClose()
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Não foi possível atualizar o processo.")
    } finally {
      setPendingAction(null)
    }
  }

  return <article className="react-dashboard__context-item">
    <a href={item.path}>{item.internal_number}</a>
    <form onSubmit={(event) => submit(event, "responsible")}>
      <label>Responsável do processo {item.internal_number}<input value={responsibleName} onChange={(event) => setResponsibleName(event.target.value)} required /></label>
      <button disabled={pendingAction !== null} type="submit">{pendingAction === "responsible" ? "Salvando…" : `Salvar responsável de ${item.internal_number}`}</button>
    </form>
    <form onSubmit={(event) => submit(event, "next-action")}>
      <label>Próxima providência do processo {item.internal_number}<input value={nextAction} onChange={(event) => setNextAction(event.target.value)} required /></label>
      <button disabled={pendingAction !== null} type="submit">{pendingAction === "next-action" ? "Salvando…" : `Salvar próxima providência de ${item.internal_number}`}</button>
    </form>
    {error && <small role="alert">{error}</small>}
  </article>
}
