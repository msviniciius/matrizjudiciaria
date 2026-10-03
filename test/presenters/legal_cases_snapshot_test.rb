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
    @other_unit_case = create_full_legal_case(
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
      matrix_mode: false,
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
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false,
      matrix_mode: false,
      filters: {}
    )

    assert_equal [ @case.id ], snapshot.as_json.fetch(:legal_cases).pluck(:id)
  end

  test "serializes no cases without an active unit outside all-units mode" do
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: nil,
      all_units_mode: false,
      matrix_mode: false,
      filters: {}
    )

    assert_empty snapshot.as_json.fetch(:legal_cases)
  end

  test "serializes only matrix cases from the requested office in matrix mode" do
    matrix_case = create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-MATRIX",
      office: @office,
      unit: nil
    )
    other_office = Office.create!(name: "Outro Escritório", slug: "outro-escritorio")
    other_client = Client.create!(
      full_name: "Cliente de outro escritório",
      cpf_cnpj: "99999999999",
      office: other_office
    )
    create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-OTHER-OFFICE",
      office: other_office,
      client: other_client,
      unit: nil
    )
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: nil,
      all_units_mode: false,
      matrix_mode: true,
      filters: {}
    )

    assert_equal [ matrix_case.id ], snapshot.as_json.fetch(:legal_cases).pluck(:id)
  end

  test "serializes every case from the requested office in all-units mode" do
    matrix_case = create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-ALL-UNITS",
      office: @office,
      unit: nil
    )
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: nil,
      all_units_mode: true,
      matrix_mode: false,
      filters: {}
    )

    assert_equal [ @case.id, @other_unit_case.id, matrix_case.id ].sort,
      snapshot.as_json.fetch(:legal_cases).pluck(:id).sort
  end

  test "marks every future deadline as upcoming" do
    future_case = create_full_legal_case(
      internal_number: "PROC-SNAPSHOT-003",
      office: @office,
      unit: @unit,
      next_deadline_on: Date.current + 8.days
    )
    snapshot = LegalCasesSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false,
      matrix_mode: false,
      filters: {}
    )

    entry = snapshot.as_json.fetch(:legal_cases).find { |record| record[:id] == future_case.id }

    assert_equal "upcoming", entry.fetch(:deadline_tone)
  end
end
