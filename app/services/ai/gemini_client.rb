require "json"
require "net/http"

module Ai
  class GeminiClient
    class ConfigurationError < StandardError; end
    class QuotaExceeded < StandardError; end
    class ResponseError < StandardError; end

    ENDPOINT = "https://generativelanguage.googleapis.com/v1beta"

    def initialize(api_key: ENV["GEMINI_API_KEY"], model: ENV.fetch("GEMINI_MODEL", "gemini-2.5-pro"))
      @api_key = api_key.to_s
      @model = model.to_s
    end

    def generate_process_analysis(payload:)
      raise ConfigurationError, "GEMINI_API_KEY ausente" if api_key.blank?

      response = Net::HTTP.post(uri, request_body(payload).to_json, headers)
      body = parse_response_body(response)
      raise QuotaExceeded, quota_exceeded_message if response.code == "429"
      raise "Gemini API retornou #{response.code}: #{body.inspect}" unless response.is_a?(Net::HTTPSuccess)

      parse_output(body)
    end

    private

    attr_reader :api_key, :model

    def uri
      URI("#{ENDPOINT}/#{model_resource}:generateContent?#{URI.encode_www_form(key: api_key)}")
    end

    def headers
      { "Content-Type" => "application/json" }
    end

    def request_body(payload)
      {
        contents: [
          {
            parts: [
              { text: prompt(payload) }
            ]
          }
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: response_schema
        }
      }
    end

    def prompt(payload)
      <<~PROMPT
        Você é um assistente de controladoria jurídica brasileira.
        Analise somente os dados fornecidos. Não invente fatos, prazos ou decisões.
        Não dê aconselhamento jurídico definitivo. Gere uma sugestão operacional para revisão humana.

        Dados estruturados do processo:
        #{JSON.pretty_generate(payload)}
      PROMPT
    end

    def response_schema
      {
        type: "object",
        properties: {
          summary: { type: "string" },
          risks: { type: "array", items: { type: "string" } },
          suggested_action: { type: "string" },
          confidence: { type: "string", enum: %w[low medium high] },
          notes: { type: "string" }
        },
        required: %w[summary risks suggested_action confidence notes]
      }
    end

    def parse_output(body)
      text = body.dig("candidates", 0, "content", "parts", 0, "text")
      raise ResponseError, "Gemini não retornou uma análise em JSON." if text.blank?

      JSON.parse(text.to_s)
    rescue JSON::ParserError => error
      raise ResponseError, "Gemini retornou JSON inválido: #{error.message}"
    end

    def parse_response_body(response)
      raise ResponseError, "Gemini retornou uma resposta vazia." if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError => error
      raise ResponseError, "Gemini retornou uma resposta inválida: #{error.message}"
    end

    def model_resource
      model.start_with?("models/") ? model : "models/#{model}"
    end

    def quota_exceeded_message
      "Limite de uso do Gemini excedido. Tente novamente em alguns instantes ou revise o plano/chave da API."
    end
  end
end
