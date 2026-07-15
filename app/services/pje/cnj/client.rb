require "net/http"
require "json"

module Pje
  module Cnj
    class Client
      class ConfigurationError < StandardError; end
      class RequestError < StandardError; end
      class ApiError < StandardError; end

      def initialize
        @base_url = ENV.fetch("CNJ_PJE_BASE_URL", "")
        @api_key = ENV.fetch("CNJ_PJE_API_KEY", "")
        @tribunal = ENV.fetch("CNJ_PJE_TRIBUNAL_ALIAS", "tjma")

        raise ConfigurationError, "CNJ_PJE_BASE_URL ausente" if @base_url.blank?
        raise ConfigurationError, "CNJ_PJE_API_KEY ausente" if @api_key.blank?
      end

      # Busca um processo pelo numero no tribunal configurado.
      # Retorna o hit do Elasticsearch ou nil se nao encontrar.
      def fetch_case(numero_processo)
        body = {
          query: {
            match: { numeroProcesso: numero_processo }
          },
          size: 1
        }

        response = post("/api_publica_#{@tribunal}/_search", body)
        hits = response.dig("hits", "hits") || []
        hits.first
      end

      # Busca processos por parametros Elasticsearch.
      # Retorna o hash completo da resposta.
      def search(body = {})
        post("/api_publica_#{@tribunal}/_search", body)
      end

      # Processa multiplas chamadas reaproveitando a mesma conexao HTTP.
      # Passa o client para o bloco, que pode chamar fetch_case e search
      # sem recriar a conexao TCP/TLS a cada chamada.
      #
      # Uso:
      #   client = Pje::Cnj::Client.new
      #   client.with_persistent_connection do |conn|
      #     legal_cases.each { |lc| conn.fetch_case(lc.external_number) }
      #   end
      def with_persistent_connection
        uri = URI(@base_url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                        open_timeout: 15, read_timeout: 60) do |http|
          @persistent_http = http
          yield self
        end
      ensure
        @persistent_http = nil
      end

      private

      def post(path, body)
        response = if @persistent_http
          post_with_connection(@persistent_http, path, body)
        else
          uri = URI("#{@base_url}#{path}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 15
          http.read_timeout = 60 # API do CNJ e lenta (~8-10s por chamada)
          post_with_connection(http, path, body)
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise RequestError, "CNJ #{@base_url}#{path} falhou: #{response.code} #{response.body.to_s[0..500]}"
        end

        parse_json!(response.body)
      end

      def post_with_connection(http, path, body)
        request = Net::HTTP::Post.new(path)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "ApiKey #{@api_key}"
        request.body = body.to_json
        http.request(request)
      end

      def parse_json!(body)
        return {} if body.nil? || body.strip.empty?

        JSON.parse(body)
      rescue JSON::ParserError => e
        Rails.logger.error "[CNJ] JSON::ParserError: #{e.message} | body: #{body.to_s[0..300]}"
        raise ApiError, "Falha ao decodificar resposta JSON da API CNJ: #{e.message}"
      end
    end
  end
end
