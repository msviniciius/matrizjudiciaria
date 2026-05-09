class DashboardController < ApplicationController
  def index
    @legal_cases = current_office.legal_cases.order(updated_at: :desc)
    operational_scope = current_office.legal_cases.operational
    deadlines_scope = Deadline.joins(:legal_case).where(legal_cases: { office_id: current_office.id })
    tasks_scope = Task.joins(:legal_case).where(legal_cases: { office_id: current_office.id })

    @report_counts = {
      por_fase: current_office.legal_cases.group(:phase).count,
      prazo_proximo: @legal_cases.with_upcoming_deadline.count,
      sem_prazo: @legal_cases.without_deadline.count,
      com_pericia: @legal_cases.with_pericia.count,
      com_exigencia_pendente: @legal_cases.with_pending_requirement.count,
      saude_critica: @legal_cases.count(&:health_status_vermelho?)
    }

    @risk_counts = {
      vence_hoje: operational_scope.deadline_due_today.count,
      vence_48h: operational_scope.deadline_due_in_48h.count,
      atrasados: operational_scope.deadline_overdue.count,
      sem_proxima_providencia: operational_scope.without_next_action.count
    }

    @risk_queues = {
      vence_hoje: operational_scope.deadline_due_today.order(:next_deadline_on, :updated_at).limit(6),
      vence_48h: operational_scope.deadline_due_in_48h.order(:next_deadline_on, :updated_at).limit(6),
      atrasados: operational_scope.deadline_overdue.order(:next_deadline_on, :updated_at).limit(6),
      sem_proxima_providencia: operational_scope.without_next_action.order(updated_at: :desc).limit(6)
    }

    @today_counts = {
      deadlines_today: deadlines_scope.where(due_date: Date.current).where.not(status: :completed).count,
      deadlines_overdue: deadlines_scope.where("due_date < ?", Date.current).where.not(status: :completed).count,
      tasks_today: tasks_scope.where(due_date: Date.current).where.not(status: :completed).count,
      tasks_overdue: tasks_scope.where("due_date < ?", Date.current).where.not(status: :completed).count
    }

    @recent_movements = ProcessMovement
      .joins(:process)
      .where(legal_cases: { office_id: current_office.id })
      .includes(:process, :movement_type)
      .order(event_date: :desc, created_at: :desc)
      .limit(8)

    @chart_data = build_chart_data
  end

  private

  def build_chart_data
    phase_counts = @report_counts[:por_fase]
    status_counts = current_office.legal_cases.group(:status).count
    responsible_counts = current_office.legal_cases
      .where.not(responsible_name: [ nil, "" ])
      .group(:responsible_name)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(8)
      .count

    {
      phase: {
        labels: phase_counts.keys.map { |key| phase_label_for(key) },
        values: phase_counts.values
      },
      status: {
        labels: status_counts.keys.map { |key| status_label_for(key) },
        values: status_counts.values
      },
      deadlines: {
        labels: [ "Atrasados", "Vence hoje", "48h", "Próximos 7 dias" ],
        values: [
          @risk_counts[:atrasados],
          @risk_counts[:vence_hoje],
          @risk_counts[:vence_48h],
          @report_counts[:prazo_proximo]
        ]
      },
      responsible: {
        labels: responsible_counts.keys,
        values: responsible_counts.values
      }
    }
  end

  def phase_label_for(value)
    I18n.t("activerecord.attributes.legal_case.phases.#{value}", default: value.to_s.humanize)
  end

  def status_label_for(value)
    I18n.t("activerecord.attributes.legal_case.statuses.#{value}", default: value.to_s.humanize)
  end
end
