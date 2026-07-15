class OfficeCalendarExporter
  PRODID = "-//Matriz Juridica//Calendario do Escritorio//PT-BR".freeze

  def initialize(office)
    @office = office
  end

  def to_ics
    lines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:#{PRODID}",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "X-WR-CALNAME:#{escape_text(@office.name)}"
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
    Deadline
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: @office.id })
      .where.not(due_date: nil)
      .where.not(status: :completed)
      .order(:due_date)
      .map do |deadline|
        client = deadline.legal_case.client&.full_name
        process = deadline.legal_case.internal_number

        {
          uid: "deadline-#{deadline.id}@matrizjuridica.local",
          summary: deadline.title,
          description: [
            "Processo #{process}",
            client ? "Cliente: #{client}" : nil,
            "Tipo: #{deadline.deadline_type}",
            deadline.responsible_name.present? ? "Responsável: #{deadline.responsible_name}" : nil
          ].compact.join("\n"),
          starts_at: deadline.due_date,
          ends_at: deadline.due_date + 1.day,
          all_day: true
        }
      end
  end

  def task_events
    Task
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: @office.id })
      .where.not(due_date: nil)
      .where.not(status: :completed)
      .order(:due_date)
      .map do |task|
        client = task.legal_case.client&.full_name
        process = task.legal_case.internal_number

        {
          uid: "task-#{task.id}@matrizjuridica.local",
          summary: task.title,
          description: [
            "Processo #{process}",
            client ? "Cliente: #{client}" : nil,
            task.responsible_name.present? ? "Responsável: #{task.responsible_name}" : nil
          ].compact.join("\n"),
          starts_at: task.due_date,
          ends_at: task.due_date + 1.day,
          all_day: true
        }
      end
  end

  def exam_events
    ProcessExam
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: @office.id }, active: true)
      .where.not(scheduled_at: nil)
      .order(:scheduled_at)
      .map do |exam|
        client = exam.legal_case.client&.full_name
        process = exam.legal_case.internal_number

        {
          uid: "exam-#{exam.id}@matrizjuridica.local",
          summary: "Perícia: #{exam.exam_nature.humanize} (#{exam.exam_scope.humanize})",
          description: [
            "Processo #{process}",
            client ? "Cliente: #{client}" : nil,
            "Status: #{exam.status.humanize}",
            exam.location.presence ? "Local: #{exam.location}" : nil
          ].compact.join("\n"),
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
