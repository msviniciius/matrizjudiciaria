class InternalCalendarsController < ApplicationController
  VISIBLE_DEADLINE_STATUSES = %w[pending in_progress overdue extended].freeze
  VISIBLE_TASK_STATUSES = %w[pending in_progress].freeze

  def index
    @view_mode = params[:view] == "list" ? "list" : "month"
    @reference_month = parse_reference_month(params[:month])
    @month_label = I18n.l(@reference_month, format: "%B de %Y").capitalize
    @previous_month_param = (@reference_month - 1.month).strftime("%Y-%m")
    @next_month_param = (@reference_month + 1.month).strftime("%Y-%m")

    @calendar_start = @reference_month.beginning_of_month.beginning_of_week(:monday)
    @calendar_end = @reference_month.end_of_month.end_of_week(:monday)
    @calendar_weeks = (@calendar_start..@calendar_end).to_a.each_slice(7).to_a

    @events = build_events(@calendar_start, @calendar_end)
    @events_by_day = @events.group_by { |event| event[:date] }
    @list_events = @events.sort_by { |event| [ event[:date], event[:time] || Time.zone.at(0) ] }

    @google_calendar_url = build_google_calendar_url
  end

  def google_calendar
    public_base_url = ENV["APP_PUBLIC_URL"].presence || request.base_url
    feed_url = "#{public_base_url.chomp('/')}#{office_calendar_feed_path(token: current_office.calendar_feed_token)}"
    subscribe_url = feed_url.sub(/\Ahttps?:\/\//, "webcal://")
    google_url = GoogleCalendarLinkBuilder.subscribe_url(subscribe_url)

    redirect_to google_url, allow_other_host: true
  end

  private

  def build_google_calendar_url
    return nil if current_office.blank?

    public_base_url = ENV["APP_PUBLIC_URL"].presence
    return nil if public_base_url.blank?

    feed_url = "#{public_base_url.chomp('/')}#{office_calendar_feed_path(token: current_office.calendar_feed_token)}"
    subscribe_url = feed_url.sub(/\Ahttps?:\/\//, "webcal://")
    GoogleCalendarLinkBuilder.subscribe_url(subscribe_url)
  rescue => e
    Rails.logger.warn "[GoogleCalendar] Erro ao gerar URL: #{e.message}"
    nil
  end

  def parse_reference_month(raw_month)
    return Date.current.beginning_of_month if raw_month.blank?

    Date.strptime(raw_month, "%Y-%m").beginning_of_month
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def build_events(range_start, range_end)
    office_id = current_office&.id
    return [] if office_id.blank?

    deadlines = Deadline
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: office_id })
      .where(status: VISIBLE_DEADLINE_STATUSES)
      .where(due_date: range_start..range_end)
      .order(:due_date)

    tasks = Task
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: office_id })
      .where(status: VISIBLE_TASK_STATUSES)
      .where(due_date: range_start..range_end)
      .order(:due_date)

    exams = ProcessExam
      .joins(:legal_case)
      .includes(:legal_case)
      .where(legal_cases: { office_id: office_id }, active: true)
      .where.not(scheduled_at: nil)
      .where(scheduled_at: range_start.beginning_of_day..range_end.end_of_day)
      .order(:scheduled_at)

    deadline_events = deadlines.map do |deadline|
      process_label = deadline.legal_case.internal_number

      {
        type: :deadline,
        type_label: "Prazo",
        date: deadline.due_date,
        time: nil,
        time_label: nil,
        title: compact_event_title(deadline.title, process_label),
        process_label: process_label,
        detail: deadline.deadline_type.present? ? translate_deadline_type(deadline.deadline_type) : "-",
        url: deadline_path(deadline)
      }
    end

    task_events = tasks.map do |task|
      process_label = task.legal_case.internal_number

      {
        type: :task,
        type_label: "Tarefa",
        date: task.due_date,
        time: nil,
        time_label: nil,
        title: compact_event_title(task.title, process_label),
        process_label: process_label,
        detail: task.responsible_name.presence || "-",
        url: task_path(task)
      }
    end

    exam_events = exams.map do |exam|
      {
        type: :exam,
        type_label: "Perícia",
        date: exam.scheduled_at.to_date,
        time: exam.scheduled_at,
        time_label: I18n.l(exam.scheduled_at, format: "%H:%M"),
        title: "#{translate_exam_nature(exam.exam_nature)} (#{translate_exam_scope(exam.exam_scope)})",
        process_label: exam.legal_case.internal_number,
        detail: translate_exam_status(exam.status),
        url: legal_case_path(exam.legal_case)
      }
    end

    (deadline_events + task_events + exam_events).sort_by do |event|
      [ event[:date], event[:time] || Time.zone.at(0), event[:type_label] ]
    end
  end

  def translate_deadline_type(value)
    I18n.t(
      "activerecord.attributes.deadline.deadline_types.#{value}",
      default: value.to_s.humanize
    )
  end

  def translate_exam_nature(value)
    I18n.t(
      "activerecord.attributes.process_exam.exam_natures.#{value}",
      default: value.to_s.humanize
    )
  end

  def translate_exam_scope(value)
    I18n.t(
      "activerecord.attributes.process_exam.exam_scopes.#{value}",
      default: value.to_s.humanize
    )
  end

  def translate_exam_status(value)
    I18n.t(
      "activerecord.attributes.process_exam.statuses.#{value}",
      default: value.to_s.humanize
    )
  end

  def compact_event_title(raw_title, process_label)
    title = raw_title.to_s.squish
    return process_label if title.blank?

    process = process_label.to_s.strip
    return title if process.blank?

    cleaned_title = title
      .gsub(/#{Regexp.escape(process)}/i, "")
      .gsub(/\A[\s\-\:\|–]+\z/, "")
      .gsub(/\A[\s\-\:\|–]+/, "")
      .gsub(/[\s\-\:\|–]+\z/, "")
      .squish

    cleaned_title.presence || title
  end
end
