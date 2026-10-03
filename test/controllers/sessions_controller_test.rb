require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @office = Office.order(:id).first || default_office
    @office.logo.detach if @office.logo.attached?
  end

  test "login renders the default office logo" do
    @office.logo.attach(logo_upload(filename: "login-logo.png"))

    get login_path

    assert_response :success
    assert_select "img.auth-logo[src*='/rails/active_storage/']", count: 1
    assert_select ".auth-logo-placeholder", count: 0
  end

  test "login renders fallback when default office has no logo" do
    get login_path

    assert_response :success
    assert_select "img.auth-logo", count: 0
    assert_select ".auth-logo-placeholder", count: 1
  end
end
