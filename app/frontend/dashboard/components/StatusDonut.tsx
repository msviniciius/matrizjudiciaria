export type DistributionItem = { label: string; count: number; path: string }

type StatusDonutProps = {
  items: DistributionItem[]
  onSelect: (item: DistributionItem) => void
  selectedPath?: string
}

const colors = ["#ff98ae", "#ffd77b", "#78efd0", "#73b7ff", "#c6a8ff"]

export function StatusDonut({ items, onSelect, selectedPath }: StatusDonutProps) {
  const total = items.reduce((sum, item) => sum + item.count, 0) || 1
  let offset = 0

  return <div className="react-dashboard__chart" aria-label="Distribuição por status">
    <svg className="react-dashboard__donut" role="img" aria-label="Distribuição por status" viewBox="0 0 120 120">
      <title>Distribuição por status</title>
      {items.map((item, index) => {
        const segment = item.count / total * 100
        const dash = `${segment} ${100 - segment}`
        const segmentOffset = -offset
        offset += segment
        return <circle className="react-dashboard__donut-segment" cx="60" cy="60" fill="none" key={item.path} r="42" stroke={colors[index % colors.length]} strokeDasharray={dash} strokeDashoffset={segmentOffset} strokeWidth="16">
          <title>{`${item.label}: ${item.count} processos`}</title>
        </circle>
      })}
      <text className="react-dashboard__chart-total" x="60" y="57">{items.reduce((sum, item) => sum + item.count, 0)}</text>
      <text className="react-dashboard__chart-caption" x="60" y="70">processos</text>
    </svg>
    <div className="react-dashboard__chart-options">
      {items.map((item, index) => <button aria-label={`${item.label}: ${item.count} processos`} aria-pressed={selectedPath === item.path} className="react-dashboard__chart-option" key={item.path} onClick={() => onSelect(item)} type="button">
        <span aria-hidden="true" className="react-dashboard__chart-swatch" style={{ backgroundColor: colors[index % colors.length] }} />
        <span>{item.label}</span><strong>{item.count}</strong>
      </button>)}
    </div>
  </div>
}
