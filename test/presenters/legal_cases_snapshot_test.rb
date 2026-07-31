require "test_helper"

class LegalCasesSnapshotTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  setup do
    create_case_dependencies

    @office = default_office
    @unit = Unit.create!(office: @office, name: "Contencioso")
    other_unit = Unit.create!(office: @office, name: "Consultivo")

    @case = create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-001",
      office: @office,
      unit: @unit,
      next_deadline_on: Date.current - 1.day
    )
    create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-002",
      office: @office,
      unit: other_unit,
      next_deadline_on: Date.current - 1.day
    )
  end

  test "serializes the filtered cases with operational fields" do
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false,
      filters: { status: "em_analise" }
    )

    entry = snapshot.as_json.fetch(:legal_cases).sole

    assert_equal @case.id, entry.fetch(:id)
    assert_equal legal_case_path(@case), entry.fetch(:path)
    assert_equal "Em análise", entry.fetch(:status_label)
    assert_equal "Média", entry[:priority_label]
    assert_equal "overdue", entry.fetch(:deadline_tone)
  end

  test "does not serialize cases outside the selected unit" do
    snapshot = LegalCasesSnapshot.new(office: @office, unit: @unit, all_units_mode: false, filters: {})

    assert_equal [ @case.id ], snapshot.as_json.fetch(:legal_cases).pluck(:id)
  end

  test "serializes no cases without an active unit outside all-units mode" do
    snapshot = LegalCasesSnapshot.new(office: @office, unit: nil, all_units_mode: false, filters: {})

    assert_empty snapshot.as_json.fetch(:legal_cases)
  end

  test "marks every future deadline as upcoming" do
    future_case = create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-003",
      office: @office,
      unit: @unit,
      next_deadline_on: Date.current + 8.days
    )
    snapshot = LegalCasesSnapshot.new(office: @office, unit: @unit, all_units_mode: false, filters: {})

    entry = snapshot.as_json.fetch(:legal_cases).find { |record| record[:id] == future_case.id }

    assert_equal "upcoming", entry.fetch(:deadline_tone)
  end
end
