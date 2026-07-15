class DailyClosureReport
  attr_reader :reference_date

  def initialize(reference_date: Date.current, scope: LegalCase.all)
    @reference_date = reference_date.to_date
    @scope = scope
  end

  def rows
    @rows ||= begin
      case_ids = @scope.pluck(:id)
      return [] if case_ids.empty?

      base_data = load_base_data
      counts = load_aggregated_counts(case_ids)

      merge_and_group(base_data, counts)
    end
  end

  private

  # Carrega apenas as colunas necessarias dos casos, sem associacoes
  def load_base_data
    @scope.select(
      :id, :responsible_name, :support_team,
      :next_deadline_on, :next_action, :last_movement_at,
      :phase, :status
    ).map do |lc|
      {
        id: lc.id,
        responsible_name: lc.responsible_name.presence || "Sem responsável",
        support_team: lc.support_team.presence || "Sem equipe",
        next_deadline_on: lc.next_deadline_on,
        next_action: lc.next_action,
        last_movement_at: lc.last_movement_at,
        phase: lc.phase,
        status: lc.status
      }
    end
  end

  # Executa agregacoes no banco para evitar carregar registros em memoria
  def load_aggregated_counts(case_ids)
    {
      movements_today: ProcessMovement
        .where(process_id: case_ids)
        .where("event_date::date = ?", @reference_date)
        .group(:process_id).count,

      deadlines_due_today: Deadline
        .where(legal_case_id: case_ids)
        .where(due_date: @reference_date)
        .where.not(status: :completed)
        .group(:legal_case_id).count,

      overdue_deadlines: Deadline
        .where(legal_case_id: case_ids)
        .where("due_date < ?", @reference_date)
        .where.not(status: :completed)
        .group(:legal_case_id).count,

      tasks_due_today: Task
        .where(legal_case_id: case_ids)
        .where(due_date: @reference_date)
        .where(status: %w[pending in_progress])
        .group(:legal_case_id).count,

      tasks_completed_today: Task
        .where(legal_case_id: case_ids)
        .where(status: :completed)
        .where("updated_at::date = ?", @reference_date)
        .group(:legal_case_id).count
    }
  end

  def merge_and_group(base_data, counts)
    rows = base_data.map do |case_data|
      id = case_data[:id]
      {
        responsible_name: case_data[:responsible_name],
        support_team: case_data[:support_team],
        processes_count: 1,
        movements_today: counts[:movements_today].fetch(id, 0),
        deadlines_due_today: counts[:deadlines_due_today].fetch(id, 0),
        overdue_deadlines: counts[:overdue_deadlines].fetch(id, 0),
        tasks_due_today: counts[:tasks_due_today].fetch(id, 0),
        tasks_completed_today: counts[:tasks_completed_today].fetch(id, 0),
        red_health_cases: health_status_vermelha?(case_data) ? 1 : 0
      }
    end

    rows
      .group_by { |r| [ r[:responsible_name], r[:support_team] ] }
      .map do |(responsible_name, support_team), group_rows|
        {
          responsible_name: responsible_name,
          support_team: support_team,
          processes_count: group_rows.sum { |r| r[:processes_count] },
          movements_today: group_rows.sum { |r| r[:movements_today] },
          deadlines_due_today: group_rows.sum { |r| r[:deadlines_due_today] },
          overdue_deadlines: group_rows.sum { |r| r[:overdue_deadlines] },
          tasks_due_today: group_rows.sum { |r| r[:tasks_due_today] },
          tasks_completed_today: group_rows.sum { |r| r[:tasks_completed_today] },
          red_health_cases: group_rows.sum { |r| r[:red_health_cases] }
        }
      end
      .sort_by { |row| [ -row[:overdue_deadlines], -row[:deadlines_due_today], row[:responsible_name] ] }
  end

  # Calcula health status em Ruby usando o calculator compartilhado
  def health_status_vermelha?(case_data)
    LegalCaseHealthCalculator.new(case_data).vermelho?
  end
end
