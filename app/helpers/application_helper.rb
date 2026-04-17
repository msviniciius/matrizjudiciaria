module ApplicationHelper
  def app_product_name
    "Matriz Jurídica"
  end

  def app_context_name
    "Gestão Processual"
  end

  def law_firm_name
    ENV.fetch("OFFICE_NAME", "Kayran Advocacia")
  end

  def enum_label(model_class, enum_name, value)
    return "" if value.blank?

    I18n.t(
      "activerecord.attributes.#{model_class.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{value}",
      default: value.to_s.humanize
    )
  end

  def enum_options_for(model_class, enum_name)
    model_class.public_send(enum_name.to_s.pluralize).keys.map do |value|
      [ enum_label(model_class, enum_name, value), value ]
    end
  end

  def legal_case_health_label(legal_case)
    case legal_case.health_status
    when "verde" then "Organizado"
    when "amarelo" then "Atenção"
    else "Crítico"
    end
  end

  def legal_case_health_class(legal_case)
    case legal_case.health_status
    when "verde" then "status-pill status-pill--success"
    when "amarelo" then "status-pill status-pill--warning"
    else "status-pill status-pill--danger"
    end
  end

  def legal_case_primary_alert(legal_case)
    return "Existe prazo vencido" if legal_case.deadline_overdue?
    return "Prazo vence hoje" if legal_case.next_deadline_on == Date.current
    return "Preencher próxima providência" if legal_case.next_action.blank?
    return "Definir responsável" if legal_case.responsible_name.blank?
    return "Atualizar andamento (mais de 15 dias)" if legal_case.stale_last_movement?

    "Sem risco crítico no momento"
  end

  def legal_case_health_reasons(legal_case)
    reasons = []
    reasons << "Existe pelo menos um prazo já vencido." if legal_case.deadline_overdue?
    reasons << "O campo \"Próxima providência\" está vazio." if legal_case.next_action.blank?
    reasons << "O campo \"Responsável\" está vazio." if legal_case.responsible_name.blank?
    reasons << "O campo \"Próximo prazo\" está vazio para este status." if legal_case.next_deadline_required? && legal_case.next_deadline_on.blank?
    reasons << "Não há atualização registrada nos últimos 15 dias." if legal_case.stale_last_movement?
    reasons << "Há prazo com vencimento nos próximos 7 dias." if legal_case.prazo_alerta? && !legal_case.deadline_overdue?
    reasons.presence || [ "As informações operacionais estão preenchidas e sem risco imediato." ]
  end

  def legal_case_health_actions(legal_case)
    actions = []
    actions << "Preencha \"Próxima providência\" com a ação que deve ser executada agora." if legal_case.next_action.blank?
    actions << "Preencha \"Responsável\" com quem está à frente do caso." if legal_case.responsible_name.blank?
    actions << "Preencha \"Próximo prazo\" com a data limite da próxima ação." if legal_case.next_deadline_required? && legal_case.next_deadline_on.blank?
    actions << "Replaneje o caso e trate imediatamente os prazos vencidos." if legal_case.deadline_overdue?
    actions << "Registre um novo andamento para atualizar o histórico do processo." if legal_case.stale_last_movement?
    actions << "Revise as tarefas e prazos que vencem nesta semana." if legal_case.prazo_alerta? && !legal_case.deadline_overdue?
    actions.presence || [ "Manter o acompanhamento diário e atualizar o processo sempre que houver novidade." ]
  end
end
