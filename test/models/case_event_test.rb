require "test_helper"

class CaseEventTest < ActiveSupport::TestCase
  test "unifica fase pelo tipo de andamento e status pelo evento" do
    movement_type = MovementType.find_or_create_by!(code: "exigencia_administrativa") do |mt|
      mt.name = "Exigência administrativa"
      mt.active = true
    end

    event = CaseEvent.new(
      legal_case: legal_cases(:one),
      entry_kind: "andamento",
      movement_type: movement_type,
      event_type: "case_closed",
      occurred_at: Time.current,
      description: "Processo encerrado por decisão administrativa"
    )

    assert event.valid?
    assert_equal "administrativo", event.phase_after
    assert_equal "encerrado", event.status_after
  end
end
