require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    default_office
  end

  test "loads the React dashboard entrypoint on the panel route" do
    get painel_path

    assert_response :success
    assert_select "script[src*='dashboard']"
  end

  test "returns the dashboard snapshot as JSON" do
    get painel_path(format: :json)

    assert_response :success
    assert_includes response.parsed_body, "kpis"
    assert_includes response.parsed_body, "critical_queues"
  end

  test "mounts the React application in the dashboard content area" do
    get painel_path

    assert_select "#react-dashboard-root"
  end

  test "updates a responsible person through JSON" do
    legal_case = create_full_legal_case(responsible_name: "")

    patch quick_update_case_responsible_path(legal_case, format: :json), params: { responsible_name: "Marina" }, as: :json

    assert_response :success
    assert_equal "Responsável do processo atualizado.", response.parsed_body.fetch("message")
    assert_equal "Marina", legal_case.reload.responsible_name
  end

  test "returns a JSON validation error for a blank responsible person" do
    legal_case = create_full_legal_case(responsible_name: "")

    patch quick_update_case_responsible_path(legal_case, format: :json), params: { responsible_name: "" }, as: :json

    assert_response :unprocessable_content
    assert_equal "Informe o responsável para atualizar o processo.", response.parsed_body.fetch("error")
  end
end
