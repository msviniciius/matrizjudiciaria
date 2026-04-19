class DailyClosureReport
  attr_reader :reference_date

  def initialize(reference_date: Date.current, scope: LegalCase.all)
    @reference_date = reference_date.to_date
    @scope = scope
  end

  def rows
    @rows ||= begin
      grouped_cases = legal_cases.group_by do |legal_case|
        [
          legal_case.responsible_name.presence || "Sem responsável",
          legal_case.support_team.presence || "Sem equipe"
        ]
      end

      grouped_cases.map do |(responsible_name, support_team), cases|
        {
          responsible_name: responsible_name,
          support_team: support_team,
          processes_count: cases.count,
          movements_today: cases.sum { |legal_case| legal_case.process_movements.count { |movement| movement.event_date.to_date == reference_date } },
          deadlines_due_today: cases.sum { |legal_case| legal_case.deadlines.count { |deadline| deadline.due_date == reference_date && !deadline.status_completed? } },
          overdue_deadlines: cases.sum { |legal_case| legal_case.deadlines.count { |deadline| deadline.due_date.present? && deadline.due_date < reference_date && !deadline.status_completed? } },
          tasks_due_today: cases.sum { |legal_case| legal_case.tasks.count { |task| task.due_date == reference_date && %w[pending in_progress].include?(task.status) } },
          tasks_completed_today: cases.sum { |legal_case| legal_case.tasks.count { |task| task.status_completed? && task.updated_at.to_date == reference_date } },
          red_health_cases: cases.count(&:health_status_vermelho?)
        }
      end.sort_by { |row| [ -row[:overdue_deadlines], -row[:deadlines_due_today], row[:responsible_name] ] }
    end
  end

  private

  def legal_cases
    @legal_cases ||= @scope
      .includes(:deadlines, :tasks, :process_movements)
      .order(:responsible_name, :internal_number)
      .to_a
  end
end
