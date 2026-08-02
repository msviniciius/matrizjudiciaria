require "test_helper"
require "rack/utils"
require "uri"

class DashboardSnapshotTest < ActiveSupport::TestCase
  setup do
    @office = default_office
    @unit = Unit.create!(office: @office, name: "Contencioso")
    @other_unit = Unit.create!(office: @office, name: "Consultivo")
    @administrator = User.create!(
      office: @office,
      name: "Admin Snapshot",
      email: "admin-snapshot-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  test "serializes unassigned cases and their unit-scoped action URLs" do
    legal_case = create_full_legal_case(unit: @unit, responsible_name: "")

    snapshot = DashboardSnapshot.new(
      office: legal_case.office,
      unit: @unit,
      all_units_mode: false
    ).as_json

    entry = snapshot.fetch(:critical_queues).fetch(:without_responsible).first

    assert_equal legal_case.internal_number, entry.fetch(:internal_number)
    assert_equal "/painel/processos/#{legal_case.id}/responsavel", entry.fetch(:update_responsible_path)
    assert_equal legal_case.office.name, snapshot.dig(:meta, :office_name)
  end

  test "serializes no office data without an active unit outside all-units mode" do
    create_full_legal_case(unit: @unit, responsible_name: "", external_number: "0000001-00.2026.8.10.0001")

    snapshot = DashboardSnapshot.new(
      office: @office,
      unit: nil,
      all_units_mode: false
    ).as_json

    assert_equal 0, snapshot.dig(:meta, :syncable_count)
    assert_empty snapshot.dig(:critical_queues, :without_responsible)
    assert_empty snapshot.dig(:distribution, :phase)
    assert_empty snapshot.dig(:distribution, :status)
  end

  test "serializes only data from the active unit" do
    selected_case = create_full_legal_case(unit: @unit, responsible_name: "")
    create_full_legal_case(unit: @other_unit, responsible_name: "")

    snapshot = DashboardSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false
    ).as_json

    assert_equal [ selected_case.id ], snapshot.dig(:critical_queues, :without_responsible).pluck(:id)
    assert_equal 1, snapshot.dig(:distribution, :phase).sum { |item| item.fetch(:count) }
    assert_equal 1, snapshot.dig(:distribution, :status).sum { |item| item.fetch(:count) }
  end

  test "serializes every unit only when all-units mode is active" do
    create_full_legal_case(unit: @unit, responsible_name: "")
    create_full_legal_case(unit: @other_unit, responsible_name: "")

    snapshot = DashboardSnapshot.new(
      office: @office,
      unit: nil,
      all_units_mode: true
    ).as_json

    assert_equal 2, snapshot.dig(:critical_queues, :without_responsible).size
    assert_equal 2, snapshot.dig(:distribution, :phase).sum { |item| item.fetch(:count) }
  end

  test "serializes filtered context items with Rails quick-action paths" do
    legal_case = create_full_legal_case(unit: @unit, responsible_name: "", next_action: "")

    snapshot = DashboardSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false
    ).as_json

    status = snapshot.dig(:distribution, :status).find { |item| item.fetch(:path).include?("status=em_analise") }
    assert_not_nil status[:items]
    item = status[:items].sole

    assert_equal legal_case.id, item.fetch(:id)
    assert_equal "/legal_cases/#{legal_case.id}", item.fetch(:path)
    assert_equal "/painel/processos/#{legal_case.id}/responsavel", item.fetch(:update_responsible_path)
    assert_equal "/painel/processos/#{legal_case.id}/providencia", item.fetch(:update_next_action_path)
  end

  test "uses Rails list filters that match each contextual process preview" do
    at_risk = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-RISK",
      responsible_name: "",
      next_deadline_on: Date.current - 1.day,
      last_movement_at: Time.current
    )
    without_next_action = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-NEXT-ACTION",
      next_action: "",
      next_deadline_on: Date.current + 30.days,
      last_movement_at: Time.current
    )
    due_in_48_hours = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-48H",
      next_deadline_on: Date.current + 1.day,
      last_movement_at: Time.current
    )
    due_today = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-TODAY",
      next_deadline_on: Date.current,
      last_movement_at: Time.current
    )
    overdue = create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-OVERDUE",
      next_deadline_on: Date.current - 1.day,
      last_movement_at: Time.current
    )
    create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-LATER",
      next_deadline_on: Date.current + 5.days,
      last_movement_at: Time.current
    )
    create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-CLOSED-NEXT-ACTION",
      status: "arquivado",
      next_action: "",
      next_deadline_on: Date.current + 30.days,
      last_movement_at: Time.current
    )
    create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-CLOSED-48H",
      status: "arquivado",
      next_deadline_on: Date.current + 1.day,
      last_movement_at: Time.current
    )
    create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-CLOSED-TODAY",
      status: "arquivado",
      next_deadline_on: Date.current,
      last_movement_at: Time.current
    )
    create_full_legal_case(
      unit: @unit,
      internal_number: "PROC-CLOSED-OVERDUE",
      status: "arquivado",
      next_deadline_on: Date.current - 1.day,
      last_movement_at: Time.current
    )

    snapshot = DashboardSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false
    ).as_json

    assert_context_path_matches(snapshot.dig(:kpis, :at_risk), [ at_risk.id ])
    assert_context_path_matches(snapshot.dig(:risk_queue, :without_next_action), [ without_next_action.id ])
    assert_context_path_matches(snapshot.dig(:risk_queue, :due_in_48_hours), [ due_in_48_hours.id ])
    assert_context_path_matches(snapshot.dig(:risk_queue, :due_today), [ due_today.id ])
    assert_context_path_matches(snapshot.dig(:risk_queue, :overdue), [ overdue.id, at_risk.id ])
  end

  test "serializes financial summary only for administrators" do
    receivable = Receivable.create!(
      office: @office,
      unit: @unit,
      description: "Honorários iniciais",
      amount: 1_200,
      due_date: Date.current,
      status: "pending",
      trigger: "manual"
    )
    associate = User.create!(
      office: @office,
      name: "Associate Snapshot",
      email: "associate-snapshot-#{SecureRandom.hex(4)}@example.com",
      role: "associate",
      password: "segredo123",
      password_confirmation: "segredo123"
    )

    admin_snapshot = DashboardSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false,
      current_user: @administrator
    ).as_json
    associate_snapshot = DashboardSnapshot.new(
      office: @office,
      unit: @unit,
      all_units_mode: false,
      current_user: associate
    ).as_json

    assert_equal 1_200.to_d, admin_snapshot.dig(:financial_summary, :expected)
    assert_equal 1_200.to_d, admin_snapshot.dig(:financial_summary, :open_balance)
    assert_equal "/receivables", admin_snapshot.dig(:financial_summary, :path)
    assert_nil associate_snapshot[:financial_summary]
    assert_equal receivable.id, receivable.reload.id
  end

  private

  def assert_context_path_matches(filter, expected_ids)
    query = Rack::Utils.parse_nested_query(URI.parse(filter.fetch(:path)).query)
    result_ids = LegalCaseQuery.new(@office.legal_cases.where(unit_id: @unit.id), query).call.order(:id).pluck(:id)

    assert_equal expected_ids.sort, filter.fetch(:items).pluck(:id).sort
    assert_equal expected_ids.sort, result_ids.sort
  end
end
