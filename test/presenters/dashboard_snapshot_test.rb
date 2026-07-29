require "test_helper"

class DashboardSnapshotTest < ActiveSupport::TestCase
  test "serializes unassigned cases and their office-scoped action URLs" do
    legal_case = create_full_legal_case(responsible_name: "")

    snapshot = DashboardSnapshot.new(
      office: legal_case.office,
      unit: nil,
      all_units_mode: false
    ).as_json

    entry = snapshot.fetch(:critical_queues).fetch(:without_responsible).first

    assert_equal legal_case.internal_number, entry.fetch(:internal_number)
    assert_equal "/painel/processos/#{legal_case.id}/responsavel", entry.fetch(:update_responsible_path)
    assert_equal legal_case.office.name, snapshot.dig(:meta, :office_name)
  end
end
