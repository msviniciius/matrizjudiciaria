require "test_helper"

class AiGeminiClientTest < ActiveSupport::TestCase
  test "uses the current Gemini structured output schema field" do
    client = Ai::GeminiClient.new(api_key: "test-key", model: "gemini-test")

    body = client.send(:request_body, { process: { internal_number: "SEI01" } })

    assert_equal "application/json", body.dig(:generationConfig, :responseMimeType)
    assert body.dig(:generationConfig, :responseSchema).present?
    assert body.dig(:contents, 0, :parts, 0, :text).present?
    assert_nil body[:response_format]
  end

  test "uses the generate content endpoint for the configured model" do
    client = Ai::GeminiClient.new(api_key: "test-key", model: "gemini-test")

    uri = client.send(:uri)

    assert_equal "/v1beta/models/gemini-test:generateContent", uri.path
    assert_equal "key=test-key", uri.query
  end

  test "parses generate content response body" do
    client = Ai::GeminiClient.new(api_key: "test-key")
    body = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => {
                  "summary" => "Resumo",
                  "risks" => [],
                  "suggested_action" => "Revisar",
                  "confidence" => "medium",
                  "notes" => "Revise antes de agir."
                }.to_json
              }
            ]
          }
        }
      ]
    }

    assert_equal "Resumo", client.send(:parse_output, body).fetch("summary")
  end

  test "raises response error when generate content response has no text" do
    client = Ai::GeminiClient.new(api_key: "test-key")

    error = assert_raises(Ai::GeminiClient::ResponseError) do
      client.send(:parse_output, { "candidates" => [] })
    end

    assert_equal "Gemini não retornou uma análise em JSON.", error.message
  end

  test "raises response error when Gemini returns an empty body" do
    client = Ai::GeminiClient.new(api_key: "test-key")
    response = Struct.new(:code, :body) do
      def is_a?(klass)
        klass == Net::HTTPSuccess
      end
    end.new("200", "")

    original_post = Net::HTTP.method(:post)
    Net::HTTP.define_singleton_method(:post) { |*| response }

    error = assert_raises(Ai::GeminiClient::ResponseError) do
      client.generate_process_analysis(payload: { process: { id: 1 } })
    end

    assert_equal "Gemini retornou uma resposta vazia.", error.message
  ensure
    Net::HTTP.define_singleton_method(:post, original_post)
  end

  test "raises a quota error when Gemini returns too many requests" do
    client = Ai::GeminiClient.new(api_key: "test-key")
    response = Struct.new(:code, :body) do
      def is_a?(klass)
        klass == Net::HTTPTooManyRequests
      end
    end.new(
      "429",
      {
        error: {
          message: "You exceeded your current quota. Please retry in 24.9s.",
          code: "too_many_requests"
        }
      }.to_json
    )

    original_post = Net::HTTP.method(:post)
    Net::HTTP.define_singleton_method(:post) { |*| response }

    error = assert_raises(Ai::GeminiClient::QuotaExceeded) do
      client.generate_process_analysis(payload: { process: { id: 1 } })
    end

    assert_equal "Limite de uso do Gemini excedido. Tente novamente em alguns instantes ou revise o plano/chave da API.", error.message
  ensure
    Net::HTTP.define_singleton_method(:post, original_post)
  end
end
