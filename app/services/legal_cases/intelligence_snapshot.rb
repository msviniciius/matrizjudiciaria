module LegalCases
  class IntelligenceSnapshot
    def initialize(legal_case:)
      @legal_case = legal_case
    end

    def as_json(*)
      {
        status: status,
        summary: summary,
        suggested_action: suggested_action,
        attention_points: attention_points,
        metrics: metrics
      }
    end

    private

    attr_reader :legal_case

    def summary
      [
        "Processo #{legal_case.internal_number}",
        "de #{client_name}",
        "está em #{legal_case.status.humanize.downcase}",
        "na fase #{legal_case.phase.humanize.downcase}.",
        "Último andamento: #{last_movement_label}.",
        "Próxima providência: #{next_action_label}."
      ].join(" ")
    end

    def status
      return "critical" if overdue_deadlines_count.positive?
      return "attention" if attention_points.any?

      "stable"
    end

    def suggested_action
      if overdue_deadlines_count.positive?
        action("Regularizar prazo vencido", "Há prazo vencido pendente de tratamento.", "high")
      elsif unread_publications_count.positive?
        action("Analisar publicação mais recente", "Existem publicações ainda não lidas vinculadas ao processo.", "high")
      elsif legal_case.has_new_imported_events?
        action("Revisar andamento importado", "Há movimentações importadas que ainda precisam ser conferidas.", "medium")
      elsif legal_case.next_action_warning?
        action("Definir próxima providência", "O processo está sem próxima providência clara.", "medium")
      elsif legal_case.pericia_alerta?
        action("Acompanhar perícia", "Existe perícia pendente ou com atenção operacional.", "medium")
      else
        action("Manter acompanhamento", "Não há alerta crítico no momento.", "low")
      end
    end

    def attention_points
      points = []
      points << point("Prazo vencido", "#{overdue_deadlines_count} prazo(s) vencido(s).", "critical") if overdue_deadlines_count.positive?
      points << point("Prazo próximo", "#{upcoming_deadlines_count} prazo(s) próximo(s).", "attention") if upcoming_deadlines_count.positive?
      points << point("Publicações não lidas", "#{unread_publications_count} publicação(ões) aguardando leitura.", "attention") if unread_publications_count.positive?
      points << point("Novos andamentos", "Há andamentos importados ainda não revisados.", "attention") if legal_case.has_new_imported_events?
      points << point("Sem próxima providência", "Defina uma próxima providência para orientar a condução.", "attention") if legal_case.next_action_warning?
      points << point("Perícia pendente", "Há perícia ativa com atenção operacional.", "attention") if legal_case.pericia_alerta?
      points << point("Andamento desatualizado", "O processo está há muitos dias sem movimentação registrada.", "attention") if legal_case.stale_last_movement?
      points
    end

    def metrics
      {
        timeline_events_count: legal_case.case_events.count + legal_case.process_movements.count,
        pending_deadlines_count: pending_deadlines_count,
        overdue_deadlines_count: overdue_deadlines_count,
        pending_tasks_count: pending_tasks_count,
        unread_publications_count: unread_publications_count,
        latest_movement_label: last_movement_label,
        next_deadline_label: date_label(legal_case.next_deadline_on, fallback: "Não definido")
      }
    end

    def action(title, description, priority)
      { title: title, description: description, priority: priority }
    end

    def point(title, description, severity)
      { title: title, description: description, severity: severity }
    end

    def client_name
      legal_case.client&.full_name.presence || "cliente não informado"
    end

    def last_movement_label
      legal_case.last_movement.presence || "sem registro"
    end

    def next_action_label
      legal_case.next_action.presence || "não definida"
    end

    def pending_deadlines
      @pending_deadlines ||= legal_case.deadlines.where(status: %w[pending in_progress overdue extended])
    end

    def pending_deadlines_count
      pending_deadlines.count
    end

    def overdue_deadlines_count
      @overdue_deadlines_count ||= pending_deadlines.where("due_date < ?", Date.current).count
    end

    def upcoming_deadlines_count
      @upcoming_deadlines_count ||= pending_deadlines
        .where.not(due_date: nil)
        .where(due_date: Date.current..(Date.current + legal_case.office.deadline_alert_days.days))
        .count
    end

    def pending_tasks_count
      @pending_tasks_count ||= legal_case.tasks.where(status: %w[pending in_progress]).count
    end

    def unread_publications_count
      @unread_publications_count ||= legal_case.legal_publications.unread.count
    end

    def date_label(value, fallback:)
      value.present? ? I18n.l(value.to_date) : fallback
    end
  end
end
