require "net/http"
require "json"

module Pje
  class BaseClient
    class ConfigurationError < StandardError; end
    class RequestError < StandardError; end

    def initialize(base_url:, access_token:)
      @base_url = base_url
      @access_token = access_token

      raise ConfigurationError, "PJE base_url ausente" if @base_url.to_s.strip.empty?
      raise ConfigurationError, "PJE access_token ausente" if @access_token.to_s.strip.empty?
    end

    def get(path, params: {})
      request(:get, path, params: params)
    end

    def request(method, path, params: {}, headers: {})
      uri = build_uri(path, params)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request_class = request_class_for(method)
      req = request_class.new(uri)
      req["Accept"] = "application/json"
      req["Authorization"] = "Bearer #{@access_token}"
      headers.each { |key, value| req[key] = value }

      response = http.request(req)

      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError, "PJE #{method.to_s.upcase} #{uri} falhou: #{response.code} #{response.body}"
      end

      parse_json(response.body)
    end

    private

    def build_uri(path, params)
      base = @base_url.end_with?("/") ? @base_url : "#{@base_url}/"
      path = path.sub(%r{^/}, "")
      uri = URI.parse(base + path)
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def request_class_for(method)
      case method.to_sym
      when :get then Net::HTTP::Get
      else
        raise ArgumentError, "Metodo HTTP nao suportado: #{method}"
      end
    end

    def parse_json(body)
      return {} if body.nil? || body.strip.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end
  end
end
