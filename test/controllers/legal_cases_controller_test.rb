require "test_helper"

class LegalCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = legal_cases(:one)
  end

  test "should get index" do
    get legal_cases_url
    assert_response :success
  end

  test "should get new" do
    get new_legal_case_url
    assert_response :success
  end

  test "should create legal_case" do
    assert_difference("LegalCase.count") do
      post legal_cases_url, params: { legal_case: { claim_value: @legal_case.claim_value, client_id: @legal_case.client_id, court: @legal_case.court, district: @legal_case.district, entry_date: @legal_case.entry_date, external_number: @legal_case.external_number, internal_number: @legal_case.internal_number, legal_area: @legal_case.legal_area, main_subject: @legal_case.main_subject, opposing_party: @legal_case.opposing_party, phase: @legal_case.phase, priority: @legal_case.priority, process_type: @legal_case.process_type, protocol_date: @legal_case.protocol_date, responsible_name: @legal_case.responsible_name, status: @legal_case.status, strategic_notes: @legal_case.strategic_notes, subarea: @legal_case.subarea, support_team: @legal_case.support_team } }
    end

    assert_redirected_to legal_case_url(LegalCase.last)
  end

  test "should show legal_case" do
    get legal_case_url(@legal_case)
    assert_response :success
  end

  test "should get edit" do
    get edit_legal_case_url(@legal_case)
    assert_response :success
  end

  test "should update legal_case" do
    patch legal_case_url(@legal_case), params: { legal_case: { claim_value: @legal_case.claim_value, client_id: @legal_case.client_id, court: @legal_case.court, district: @legal_case.district, entry_date: @legal_case.entry_date, external_number: @legal_case.external_number, internal_number: @legal_case.internal_number, legal_area: @legal_case.legal_area, main_subject: @legal_case.main_subject, opposing_party: @legal_case.opposing_party, phase: @legal_case.phase, priority: @legal_case.priority, process_type: @legal_case.process_type, protocol_date: @legal_case.protocol_date, responsible_name: @legal_case.responsible_name, status: @legal_case.status, strategic_notes: @legal_case.strategic_notes, subarea: @legal_case.subarea, support_team: @legal_case.support_team } }
    assert_redirected_to legal_case_url(@legal_case)
  end

  test "should destroy legal_case" do
    assert_difference("LegalCase.count", -1) do
      delete legal_case_url(@legal_case)
    end

    assert_redirected_to legal_cases_url
  end
end
