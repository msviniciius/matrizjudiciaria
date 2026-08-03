module Integrations
  module Escavador
    class PublicationNormalizer
      SUPPORTED_DAILY_EVENTS = %w[
        diario_movimentacao_nova
        diario_citacao_nova
      ].freeze
      SUPPORTED_MOVEMENT_EVENT = "nova_movimentacao"
      CNJ_PATTERN = /\b\d{7}-?\d{2}\.?\d{4}\.?\d\.?\d{2}\.?\d{4}\b/

      def initialize(payload)
        @payload = payload.deep_stringify_keys
      end

      def call
        movement = payload.fetch("movimentacao", {})
        content = first_present(
          movement["conteudo"],
          movement["texto"],
          payload["conteudo"],
          payload["texto"]
        )

        {
          source: "escavador",
          external_id: external_id,
          event_name: event_name,
          published_at: parse_time(first_present(movement["data_publicacao"], movement["data"], payload["data"])),
          court_name: first_present(movement["tribunal"], payload["tribunal"]),
          journal_name: first_present(movement["diario"], movement["fonte"], payload["diario"]),
          process_number: first_present(movement["numero_cnj"], payload.dig("processo", "numero_cnj"), content.to_s[CNJ_PATTERN]),
          title: first_present(movement["titulo"], payload["titulo"]),
          content: content.presence || payload.to_json,
          raw_payload: payload
        }
      end

      def supported?
        return true if SUPPORTED_DAILY_EVENTS.include?(event_name)
        return false unless event_name == SUPPORTED_MOVEMENT_EVENT

        publication_movement?
      end

      private

      attr_reader :payload

      def event_name
        payload["evento"].to_s
      end

      def external_id
        first_present(
          payload["uuid"],
          payload["id"],
          payload.dig("movimentacao", "uuid"),
          payload.dig("movimentacao", "id"),
          Digest::SHA256.hexdigest(payload.to_json)
        )
      end

      def publication_movement?
        movement = payload.fetch("movimentacao", {})
        type = movement["tipo"].to_s.upcase
        source = first_present(movement["fonte"], movement["diario"], movement["origem"]).to_s.upcase

        type == "PUBLICACAO" || source.include?("DIARIO") || source.include?("DJE")
      end

      def first_present(*values)
        values.find { |value| value.respond_to?(:present?) ? value.present? : value.to_s.present? }
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
