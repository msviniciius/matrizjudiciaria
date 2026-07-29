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
end
