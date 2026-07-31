require "test_helper"

class InternalCalendarSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "serializes month calendar days and list events" do
    reference_month = Date.new(2026, 7, 1)
    event = {
      type: :deadline,
      type_label: "Prazo",
      date: Date.new(2026, 7, 30),
      time: nil,
      time_label: nil,
      title: "Prazo snapshot",
      process_label: "PROC-CAL-SNAP-001",
      detail: "Judicial",
      url: "/deadlines/1"
    }

    snapshot = InternalCalendarSnapshot.new(
      view_mode: "month",
      reference_month: reference_month,
      month_label: "Julho de 2026",
      previous_month_param: "2026-06",
      next_month_param: "2026-08",
      calendar_weeks: [ [ Date.new(2026, 7, 30) ] ],
      events_by_day: { Date.new(2026, 7, 30) => [ event ] },
      list_events: [ event ],
      google_calendar_url: "https://calendar.google.com/calendar/r?cid=feed"
    ).as_json

    assert_equal "month", snapshot.dig(:meta, :view_mode)
    assert_equal "2026-07", snapshot.dig(:meta, :reference_month)
    assert_equal "Julho de 2026", snapshot.dig(:meta, :month_label)
    assert_equal 1, snapshot.dig(:meta, :total_count)
    assert_equal internal_calendar_path(month: "2026-06", view: "month"), snapshot.dig(:actions, :previous_month)
    assert_equal "Seg", snapshot.fetch(:weekdays).first

    day = snapshot.fetch(:weeks).first.first
    assert_equal "2026-07-30", day.fetch(:date)
    assert_equal false, day.fetch(:outside_month)
    assert_equal "Prazo snapshot - PROC-CAL-SNAP-001", day.fetch(:events).sole.fetch(:display_title)
    assert_equal "Prazo", snapshot.fetch(:events).sole.fetch(:type_label)
  end
end
