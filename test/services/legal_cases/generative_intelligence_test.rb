require "test_helper"

class LegalCasesGenerativeIntelligenceTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :payload

    def generate_process_analysis(payload:)
      @payload = payload
      {
        "summary" => "Resumo gerado pela IA.",
        "risks" => [ "Prazo crítico" ],
        "suggested_action" => "Analisar publicação e confirmar prazo.",
        "confidence" => "medium",
        "notes" => "Revise antes de agir."
      }
    end
  end

  test "persists a generated process analysis from a structured client response" do
    create_case_dependencies
    legal_case = create_full_legal_case(next_action: "Analisar intimação")
    user = User.create!(
      office: default_office,
      name: "Admin IA",
      email: "admin-ia-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    client = FakeClient.new

    analysis = LegalCases::GenerativeIntelligence.new(
      legal_case: legal_case,
      user: user,
      client: client
    ).call

    assert analysis.persisted?
    assert_equal legal_case, analysis.legal_case
    assert_equal user, analysis.created_by
    assert_equal "gemini", analysis.provider
    assert_equal "Resumo gerado pela IA.", analysis.summary
    assert_equal [ "Prazo crítico" ], analysis.risks
    assert_equal "Analisar publicação e confirmar prazo.", analysis.suggested_action
    assert_equal "medium", analysis.confidence
    assert_includes client.payload.fetch(:deterministic).fetch(:summary), legal_case.internal_number
  end
end
