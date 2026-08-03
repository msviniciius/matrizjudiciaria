require "test_helper"

class JobsDashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(role: "admin")
    @attendant = create_user(role: "attendant")
  end

  test "allows administrators to access the jobs dashboard" do
    sign_in(@admin)

    get "/jobs"

    assert_response :success
  end

  test "denies jobs dashboard access to non administrators" do
    sign_in(@attendant)

    get "/jobs"

    assert_redirected_to root_path
    assert_equal "Apenas administradores podem acessar esta área.", flash[:alert]
  end

  private

  def create_user(role:)
    User.create!(
      office: default_office,
      name: "Usuário #{role}",
      email: "#{role}-jobs-#{SecureRandom.hex(4)}@example.com",
      role: role,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def sign_in(user)
    post login_path, params: { email: user.email, password: "segredo123" }
  end
end
