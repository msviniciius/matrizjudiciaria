import type { DistributionItem } from "./StatusDonut"

type PhaseBarsProps = {
  items: DistributionItem[]
  onSelect: (item: DistributionItem) => void
  selectedPath?: string
}

export function PhaseBars({ items, onSelect, selectedPath }: PhaseBarsProps) {
  const maximum = Math.max(...items.map((item) => item.count), 1)

  return <div className="react-dashboard__chart" aria-label="Distribuição por fase">
    <svg className="react-dashboard__bars" role="img" aria-label="Distribuição por fase" viewBox={`0 0 240 ${Math.max(items.length, 1) * 36}`}>
      <title>Distribuição por fase</title>
      {items.map((item, index) => {
        const width = item.count / maximum * 140
        const y = index * 36 + 6
        return <g className="react-dashboard__bar" key={item.path}>
          <title>{`${item.label}: ${item.count} processos`}</title>
          <text dominantBaseline="middle" x="0" y={y + 7}>{item.label}</text>
          <rect height="14" rx="7" width={width} x="80" y={y} />
          <text className="react-dashboard__bar-count" dominantBaseline="middle" x="238" y={y + 7}>{item.count}</text>
        </g>
      })}
    </svg>
    <div className="react-dashboard__chart-options">
      {items.map((item) => <button aria-label={`${item.label}: ${item.count} processos`} aria-pressed={selectedPath === item.path} className="react-dashboard__chart-option" key={item.path} onClick={() => onSelect(item)} type="button">
        <span>{item.label}</span><strong>{item.count}</strong>
      </button>)}
    </div>
  </div>
}
