class DashboardController < ApplicationController
  def index
    @unit_selection_required = current_user.present? && !all_units_mode? && current_unit.blank? && (current_user.admin? || current_user.available_units.exists?)
    @available_units = current_user&.available_units&.ordered || []

    if @unit_selection_required
      @legal_cases = []
      @report_counts = { por_fase: {}, prazo_proximo: 0, sem_prazo: 0, com_pericia: 0, com_exigencia_pendente: 0, saude_critica: 0 }
      @risk_counts = { vence_hoje: 0, vence_48h: 0, atrasados: 0, sem_proxima_providencia: 0 }
      @risk_queues = { vence_hoje: [], vence_48h: [], atrasados: [], sem_proxima_providencia: [] }
      @today_counts = { deadlines_today: 0, deadlines_overdue: 0, tasks_today: 0, tasks_overdue: 0 }
      @recent_movements = []
      @critical_queues = { without_responsible: [], without_next_action: [], overdue_deadlines_without_reason: [] }
      @chart_data = { phase: { labels: [], values: [] }, status: { labels: [], values: [] }, deadlines: { labels: [], values: [] }, responsible: { labels: [], values: [] } }
      return
    end

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

    @critical_queues = {
      without_responsible: operational_scope
        .where(responsible_name: [ nil, "" ])
        .order(Arel.sql("legal_cases.next_deadline_on ASC NULLS LAST, legal_cases.updated_at DESC"))
        .limit(6),
      without_next_action: operational_scope
        .where(next_action: [ nil, "" ])
        .order(Arel.sql("legal_cases.next_deadline_on ASC NULLS LAST, legal_cases.updated_at DESC"))
        .limit(6),
      overdue_deadlines_without_reason: deadlines_scope
        .where("deadlines.due_date < ?", Date.current)
        .where.not(status: :completed)
        .where("COALESCE(deadlines.delay_reason, '') = ''")
        .order(due_date: :asc)
        .limit(6)
    }

    @chart_data = build_chart_data
  end

  def quick_update_case_responsible
    legal_case = current_office.legal_cases.find(params.expect(:id))
    responsible_name = params[:responsible_name].to_s.strip

    if responsible_name.blank?
      redirect_to painel_path, alert: "Informe o responsável para atualizar o processo."
      return
    end

    legal_case.update!(responsible_name: responsible_name)
    redirect_to painel_path, notice: "Responsável do processo atualizado."
  end

  def quick_update_case_next_action
    legal_case = current_office.legal_cases.find(params.expect(:id))
    next_action = params[:next_action].to_s.strip

    if next_action.blank?
      redirect_to painel_path, alert: "Informe a próxima providência para atualizar o processo."
      return
    end

    legal_case.update!(next_action: next_action)
    redirect_to painel_path, notice: "Próxima providência atualizada."
  end

  def quick_update_deadline_reason
    deadline = Deadline.joins(:legal_case).where(legal_cases: { office_id: current_office.id }).find(params.expect(:id))
    delay_reason = params[:delay_reason].to_s.strip

    if delay_reason.blank?
      redirect_to painel_path, alert: "Informe a justificativa para regularizar o prazo."
      return
    end

    deadline.update!(delay_reason: delay_reason)
    redirect_to painel_path, notice: "Justificativa do prazo atualizada."
  end

  def quick_update_task_responsible
    task = Task.joins(:legal_case).where(legal_cases: { office_id: current_office.id }).find(params.expect(:id))
    responsible_name = params[:responsible_name].to_s.strip

    if responsible_name.blank?
      redirect_to painel_path, alert: "Informe o responsável para regularizar a tarefa."
      return
    end

    task.update!(responsible_name: responsible_name)
    redirect_to painel_path, notice: "Responsável da tarefa atualizado."
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
