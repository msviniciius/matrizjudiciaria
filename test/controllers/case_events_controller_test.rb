require "test_helper"

class CaseEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(
      internal_number: "PROC-EVT-001",
      responsible_name: "Advogado da carteira",
      next_action: "Monitorar andamento inicial"
    )

    @movement_type = MovementType.find_or_create_by!(code: "movimentacao_judicial") { |mt|
      mt.name = "Movimentacao Judicial"
    }

    @case_event = CaseEvent.create!(
      legal_case: @legal_case,
      entry_kind: "andamento",
      event_date: Time.current,
      description: "Evento inicial",
      responsible_name: "Advogado",
      movement_type: @movement_type
    )
  end

  test "should get index" do
    get case_events_url
    assert_response :success
  end

  test "should get new" do
    get new_case_event_url
    assert_response :success
  end

  test "should create case_event" do
    assert_difference("CaseEvent.count") do
      post case_events_url, params: { case_event: {
        legal_case_id: @legal_case.id,
        entry_kind: "andamento",
        event_date: Time.current,
        description: "Protocolo",
        responsible_name: "Equipe",
        movement_type_id: @movement_type.id
      } }
    end

    assert_redirected_to case_event_url(CaseEvent.last)
  end

  test "should show case_event" do
    get case_event_url(@case_event)
    assert_response :success
  end

  test "should get edit" do
    get edit_case_event_url(@case_event)
    assert_response :success
  end

  test "should update case_event" do
    patch case_event_url(@case_event), params: { case_event: {
      description: "Evento atualizado",
      entry_kind: "andamento",
      movement_type_id: @movement_type.id
    } }
    assert_redirected_to case_event_url(@case_event)
  end

  test "should destroy case_event" do
    assert_difference("CaseEvent.count", -1) do
      delete case_event_url(@case_event)
    end

    assert_redirected_to case_events_url
  end
end
