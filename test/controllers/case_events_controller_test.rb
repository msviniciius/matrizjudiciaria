require "test_helper"

class CaseEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    client = Client.create!(full_name: "Cliente Evento", cpf_cnpj: "55555555555")
    district = District.create!(name: "Caxias/MA")
    court = Court.create!(name: "4a Vara Civel", district: district)
    legal_area = LegalArea.create!(name: "Civel Geral", justice_branch: "state")
    process_type = ProcessType.create!(name: "Procedimento Comum Civel", legal_area: legal_area)

    @legal_case = LegalCase.create!(
      internal_number: "PROC-EVT-001",
      phase: "analysis",
      status: "active",
      client: client,
      legal_area_id: legal_area.id,
      process_type_id: process_type.id,
      district_id: district.id,
      court_id: court.id
    )

    @case_event = CaseEvent.create!(
      legal_case: @legal_case,
      event_type: "initial_contact",
      occurred_at: Time.current,
      description: "Evento inicial",
      responsible_name: "Advogado"
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
        event_type: "filing",
        occurred_at: Time.current,
        description: "Protocolo",
        responsible_name: "Equipe"
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
    patch case_event_url(@case_event), params: { case_event: { description: "Evento atualizado", event_type: "client_contact" } }
    assert_redirected_to case_event_url(@case_event)
  end

  test "should destroy case_event" do
    assert_difference("CaseEvent.count", -1) do
      delete case_event_url(@case_event)
    end

    assert_redirected_to case_events_url
  end
end
