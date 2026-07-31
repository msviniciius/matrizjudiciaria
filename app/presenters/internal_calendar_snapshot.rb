class InternalCalendarSnapshot
  include Rails.application.routes.url_helpers

  WEEKDAYS = %w[Seg Ter Qua Qui Sex Sáb Dom].freeze

  def initialize(view_mode:, reference_month:, month_label:, previous_month_param:, next_month_param:, calendar_weeks:, events_by_day:, list_events:, google_calendar_url:)
    @view_mode = view_mode
    @reference_month = reference_month
    @month_label = month_label
    @previous_month_param = previous_month_param
    @next_month_param = next_month_param
    @calendar_weeks = calendar_weeks
    @events_by_day = events_by_day
    @list_events = list_events
    @google_calendar_url = google_calendar_url
  end

  def as_json(*)
    {
      meta: {
        view_mode: view_mode,
        reference_month: reference_month.strftime("%Y-%m"),
        month_label: month_label,
        today_month: Date.current.strftime("%Y-%m"),
        total_count: list_events.size
      },
      weekdays: WEEKDAYS,
      weeks: calendar_weeks.map { |week| week.map { |day| day_entry(day) } },
      events: list_events.map { |event| event_entry(event) },
      actions: {
        index: internal_calendar_path,
        month: internal_calendar_path(month: reference_month.strftime("%Y-%m"), view: "month"),
        list: internal_calendar_path(month: reference_month.strftime("%Y-%m"), view: "list"),
        previous_month: internal_calendar_path(month: previous_month_param, view: view_mode),
        next_month: internal_calendar_path(month: next_month_param, view: view_mode),
        today: internal_calendar_path(month: Date.current.strftime("%Y-%m"), view: view_mode),
        google_calendar: google_calendar_url
      }
    }
  end

  private

  attr_reader :view_mode, :reference_month, :month_label, :previous_month_param, :next_month_param, :calendar_weeks, :events_by_day, :list_events, :google_calendar_url

  def day_entry(day)
    events = events_by_day.fetch(day, [])

    {
      date: day.iso8601,
      day_number: day.day,
      outside_month: day.month != reference_month.month,
      today: day == Date.current,
      events: events.map { |event| event_entry(event) }
    }
  end

  def event_entry(event)
    {
      type: event.fetch(:type).to_s,
      type_label: event.fetch(:type_label),
      date: event.fetch(:date).iso8601,
      date_label: I18n.l(event.fetch(:date), format: :short),
      time: event[:time]&.iso8601,
      time_label: event[:time_label].presence || "-",
      title: event.fetch(:title),
      process_label: event[:process_label].presence || "-",
      detail: event[:detail].presence || "-",
      url: event.fetch(:url),
      display_title: [ event.fetch(:title), event[:process_label].presence ].compact.join(" - ")
    }
  end
end
