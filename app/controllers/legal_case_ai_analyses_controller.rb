class LegalCaseAiAnalysesController < ApplicationController
  before_action :require_admin!
  before_action :set_legal_case

  class << self
    attr_accessor :generator_factory
  end

  self.generator_factory = ->(legal_case:, user:) {
    LegalCases::GenerativeIntelligence.new(legal_case: legal_case, user: user).call
  }

  def create
    analysis = self.class.generator_factory.call(legal_case: @legal_case, user: current_user)

    render json: { analysis: analysis.as_json }, status: :created
  rescue Ai::GeminiClient::ConfigurationError => error
    render json: { error: error.message }, status: :unprocessable_entity
  rescue Ai::GeminiClient::QuotaExceeded => error
    Rails.logger.warn "[AI] Limite do Gemini excedido ao gerar análise do processo #{@legal_case.id}: #{error.message}"
    render json: { error: error.message }, status: :too_many_requests
  rescue Ai::GeminiClient::ResponseError => error
    Rails.logger.warn "[AI] Resposta inválida do Gemini ao gerar análise do processo #{@legal_case.id}: #{error.message}"
    render json: { error: error.message }, status: :bad_gateway
  rescue => error
    Rails.logger.error "[AI] Falha ao gerar análise do processo #{@legal_case.id}: #{error.class} #{error.message}"
    render json: { error: "Não foi possível gerar a análise com IA." }, status: :bad_gateway
  end

  private

  def set_legal_case
    @legal_case = scope_by_current_unit(current_office.legal_cases).find(params.expect(:id))
  end
end
