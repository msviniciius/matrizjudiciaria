import { useEffect, useRef } from "react"
import type { DistributionItem } from "./StatusDonut"

type ContextPanelProps = {
  filter: DistributionItem
  onClose: () => void
}

export function ContextPanel({ filter, onClose }: ContextPanelProps) {
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    closeButtonRef.current?.focus()
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose()
    }
    document.addEventListener("keydown", closeOnEscape)
    return () => document.removeEventListener("keydown", closeOnEscape)
  }, [onClose])

  return <div className="react-dashboard__panel-overlay" onMouseDown={(event) => {
    if (event.target === event.currentTarget) onClose()
  }}>
    <aside aria-labelledby="context-panel-title" aria-modal="true" className="react-dashboard__context-panel" role="dialog">
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
