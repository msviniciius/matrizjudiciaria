require "test_helper"

class LegalCaseAiAnalysesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    @admin = User.create!(
      office: default_office,
      name: "Admin Análise",
      email: "admin-analise-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123",
      active: true
    )
    @attendant = User.create!(
      office: default_office,
      name: "Atendente Análise",
      email: "atendente-analise-#{SecureRandom.hex(4)}@example.com",
      role: "attendant",
      password: "segredo123",
      password_confirmation: "segredo123",
      active: true
    )
    @legal_case = create_full_legal_case
  end

  test "admin receives a controlled error when ai provider is not configured" do
    sign_in(@admin)

    with_env("GEMINI_API_KEY" => nil) do
      post ai_analysis_legal_case_path(@legal_case), as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "GEMINI_API_KEY ausente", response.parsed_body.fetch("error")
  end

  test "admin receives a controlled error when ai provider quota is exceeded" do
    sign_in(@admin)

    previous_factory = LegalCaseAiAnalysesController.generator_factory
    LegalCaseAiAnalysesController.generator_factory = ->(legal_case:, user:) {
      raise Ai::GeminiClient::QuotaExceeded,
        "Limite de uso do Gemini excedido. Tente novamente em alguns instantes ou revise o plano/chave da API."
    }

    post ai_analysis_legal_case_path(@legal_case), as: :json

    assert_response :too_many_requests
    assert_equal(
      "Limite de uso do Gemini excedido. Tente novamente em alguns instantes ou revise o plano/chave da API.",
      response.parsed_body.fetch("error")
    )
  ensure
    LegalCaseAiAnalysesController.generator_factory = previous_factory
  end

  test "admin receives a controlled error when ai provider response is invalid" do
    sign_in(@admin)

    previous_factory = LegalCaseAiAnalysesController.generator_factory
    LegalCaseAiAnalysesController.generator_factory = ->(legal_case:, user:) {
      raise Ai::GeminiClient::ResponseError, "Gemini não retornou uma análise em JSON."
    }

    post ai_analysis_legal_case_path(@legal_case), as: :json

    assert_response :bad_gateway
    assert_equal "Gemini não retornou uma análise em JSON.", response.parsed_body.fetch("error")
  ensure
    LegalCaseAiAnalysesController.generator_factory = previous_factory
  end

  test "non admin cannot generate ai analysis" do
    sign_in(@attendant)

    post ai_analysis_legal_case_path(@legal_case), as: :json

    assert_redirected_to root_path
  end

  private

  def sign_in(user)
    post login_path, params: { email: user.email, password: "segredo123" }
  end

  def with_env(values)
    previous_values = values.keys.to_h { |key| [ key, ENV[key] ] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous_values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
