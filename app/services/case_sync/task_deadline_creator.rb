module CaseSync
  # Servico compartilhado para criacao de Tasks e Deadlines a partir de
  # andamentos processuais (CaseEvent e ProcessMovement).
  #
  # Centraliza a logica de find_or_create_by para evitar duplicacao.
  class TaskDeadlineCreator
    def initialize(legal_case)
      @legal_case = legal_case
    end

    # Cria ou encontra uma Task com os atributos fornecidos.
    # Se a task ja existir (mesmo legal_case_id + title + due_date), nao duplica.
    def create_task(title:, due_date:, description: nil, priority: "high", responsible_name: nil)
      Task.find_or_create_by!(
        legal_case_id: @legal_case.id,
        title: title,
        due_date: due_date
      ) do |task|
        task.status = "pending"
        task.priority = priority
        task.description = description.presence || "Tarefa criada automaticamente pelo andamento processual."
        task.responsible_name = responsible_name || @legal_case.responsible_name
      end
    end

    # Cria ou encontra um Deadline com os atributos fornecidos.
    # Se o deadline ja existir (mesmo legal_case_id + title + due_date), nao duplica.
    def create_deadline(title:, due_date:, deadline_type: "internal", priority: "high",
                        responsible_name: nil, delay_reason: nil)
      # Tenta encontrar uma regra de prazo configurada para calcular a data
      due_date ||= compute_due_date_from_setting(deadline_type)

      Deadline.find_or_create_by!(
        legal_case_id: @legal_case.id,
        title: title,
        due_date: due_date
      ) do |deadline|
        deadline.deadline_type = deadline_type
        deadline.status = "pending"
        deadline.priority = priority
        deadline.delay_reason = delay_reason
        deadline.responsible_name = responsible_name || @legal_case.responsible_name
      end
    end

    # Cria Task e Deadline especificos para eventos de pericia.
    # Usado tanto por CaseEvent quanto por ProcessMovement quando ha
    # um ProcessExam vinculado.
    def create_exam_task_and_deadline(process_exam, responsible_name: nil)
      return if process_exam.blank?

      due_date = process_exam.scheduled_at&.to_date
      return if due_date.blank?

      title_base = "Providenciar perícia #{process_exam.exam_nature.humanize.downcase}"

      task = create_task(
        title: title_base,
        due_date: due_date,
        priority: "high",
        description: "Tarefa criada automaticamente a partir do andamento de perícia.",
        responsible_name: responsible_name
      )

      deadline = create_deadline(
        title: "Prazo da perícia",
        due_date: due_date,
        deadline_type: "expert_exam",
        priority: "high",
        responsible_name: responsible_name
      )

      { task: task, deadline: deadline }
    end

    private

    def compute_due_date_from_setting(deadline_type)
      return Date.current if deadline_type.blank?

      setting = @legal_case.office&.deadline_settings&.active&.find_by(deadline_type: deadline_type)
      return Date.current if setting.blank?

      Date.current + setting.days_to_due.days
    end
  end
end
