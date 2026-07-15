class LegalCaseCalendarExporter
  PRODID = "-//Matriz Juridica//Calendario Processual//PT-BR".freeze

  def initialize(legal_case)
    @legal_case = legal_case
  end

  def to_ics
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:#{PRODID}",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "X-WR-CALNAME:#{escape_text("Processo #{@legal_case.internal_number}")}"
    ]

    calendar_events.each do |event|
      lines.concat(serialize_event(event))
    end

    lines << "END:VCALENDAR"
    lines.join("\r\n")
  end

  private

  def calendar_events
    deadline_events + task_events + exam_events
  end

  def deadline_events
    @legal_case.deadlines.order(:due_date).filter_map do |deadline|
      next if deadline.due_date.blank?

      {
        uid: "deadline-#{deadline.id}-case-#{@legal_case.id}@matrizjuridica.local",
        summary: "Prazo: #{deadline.title}",
        description: [
          "Processo #{@legal_case.internal_number}",
          "Tipo: #{deadline.deadline_type}",
          "Responsável: #{deadline.responsible_name.presence || "Não informado"}"
        ].join("\n"),
        starts_at: deadline.due_date,
        ends_at: deadline.due_date + 1.day,
        all_day: true
      }
    end
  end

  def task_events
    @legal_case.tasks.where.not(due_date: nil).where.not(status: :completed).order(:due_date).filter_map do |task|
      {
        uid: "task-#{task.id}-case-#{@legal_case.id}@matrizjuridica.local",
        summary: "Tarefa: #{task.title}",
        description: [
          "Processo #{@legal_case.internal_number}",
          "Responsável: #{task.responsible_name.presence || "Não informado"}"
        ].join("\n"),
        starts_at: task.due_date,
        ends_at: task.due_date + 1.day,
        all_day: true
      }
    end
  end

  def exam_events
    @legal_case.process_exams.order(:scheduled_at).filter_map do |exam|
      next if exam.scheduled_at.blank?

      {
        uid: "exam-#{exam.id}-case-#{@legal_case.id}@matrizjuridica.local",
        summary: "Perícia: #{exam.exam_nature.humanize} (#{exam.exam_scope.humanize})",
        description: [
          "Processo #{@legal_case.internal_number}",
          "Status: #{exam.status.humanize}",
          "Local: #{exam.location.presence || "Não informado"}"
        ].join("\n"),
        starts_at: exam.scheduled_at.utc,
        ends_at: (exam.scheduled_at + 1.hour).utc,
        all_day: false
      }
    end
  end

  def serialize_event(event)
    lines = [
      "BEGIN:VEVENT",
      "UID:#{event[:uid]}",
      "DTSTAMP:#{timestamp(Time.current.utc)}",
      "SUMMARY:#{escape_text(event[:summary])}",
      "DESCRIPTION:#{escape_text(event[:description])}"
    ]

    if event[:all_day]
      lines << "DTSTART;VALUE=DATE:#{date_stamp(event[:starts_at])}"
      lines << "DTEND;VALUE=DATE:#{date_stamp(event[:ends_at])}"
    else
      lines << "DTSTART:#{timestamp(event[:starts_at])}"
      lines << "DTEND:#{timestamp(event[:ends_at])}"
    end

    lines << "END:VEVENT"
    lines
  end

  def timestamp(value)
    value.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def date_stamp(value)
    value.strftime("%Y%m%d")
  end

  def escape_text(value)
    value.to_s
      .gsub("\\", "\\\\")
      .gsub("\r\n", "\\n")
      .gsub("\n", "\\n")
      .gsub(",", "\\,")
      .gsub(";", "\\;")
  end
end
