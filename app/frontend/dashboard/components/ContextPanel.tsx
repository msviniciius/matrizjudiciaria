import { useEffect, useRef } from "react"
import type { DistributionItem } from "./StatusDonut"

type ContextPanelProps = {
  filter: DistributionItem
  onClose: () => void
  returnFocusTo: HTMLElement | null
}

export function ContextPanel({ filter, onClose, returnFocusTo }: ContextPanelProps) {
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
      <p>Consulte a lista para revisar os processos abrangidos por este filtro.</p>
      <a className="react-dashboard__context-panel-link" href={filter.path}>Ver processos filtrados</a>
    </aside>
  </div>
}
