require "test_helper"

class CaseEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @case_event = case_events(:one)
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
      post case_events_url, params: { case_event: { description: @case_event.description, event_type: @case_event.event_type, legal_case_id: @case_event.legal_case_id, occurred_at: @case_event.occurred_at, responsible_name: @case_event.responsible_name } }
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
    patch case_event_url(@case_event), params: { case_event: { description: @case_event.description, event_type: @case_event.event_type, legal_case_id: @case_event.legal_case_id, occurred_at: @case_event.occurred_at, responsible_name: @case_event.responsible_name } }
    assert_redirected_to case_event_url(@case_event)
  end

  test "should destroy case_event" do
    assert_difference("CaseEvent.count", -1) do
      delete case_event_url(@case_event)
    end

    assert_redirected_to case_events_url
  end
end
