module Integrations
  module Djma
    class PublicationMatcher
      CNJ_PATTERN = /\b\d{7}-?\d{2}\.?\d{4}\.?\d\.?\d{2}\.?\d{4}\b/
      CONTEXT_CHARACTERS = 1_200

      def initialize(text:, oab_registration:, oab_state:, process_numbers: [])
        @text = text.to_s
        @oab_registration = oab_registration.to_s.gsub(/\D/, "")
        @oab_state = oab_state.to_s.upcase.gsub(/[^A-Z]/, "")
        @process_numbers = Array(process_numbers).map(&:to_s).reject(&:blank?)
      end

      def call
        terms.flat_map { |term| matches_for_term(term) }
          .uniq { |match| [ LegalPublication.normalize_process_number(match[:process_number]), normalized_content(match[:content]) ] }
      end

      private

      attr_reader :text, :oab_registration, :oab_state, :process_numbers

      def terms
        oab_terms + process_numbers
      end

      def oab_terms
        return [] if oab_registration.blank? || oab_state.blank?

        [
          "OAB #{oab_registration}-#{oab_state}",
          "OAB/#{oab_state} #{oab_registration}",
          "#{oab_registration}-#{oab_state}"
        ]
      end

      def matches_for_term(term)
        indexes_for(term).map do |index|
          content = extract_context(index)
          {
            content: content,
            process_number: content[CNJ_PATTERN],
            matched_terms: [ term ]
          }
        end
      end

      def indexes_for(term)
        normalized_text = normalize_for_search(text)
        normalized_term = normalize_for_search(term)
        indexes = []
        offset = 0

        while (index = normalized_text.index(normalized_term, offset))
          indexes << index
          offset = index + normalized_term.length
        end

        indexes
      end

      def extract_context(index)
        start_position = [ index - CONTEXT_CHARACTERS, 0 ].max
        end_position = [ index + CONTEXT_CHARACTERS, text.length ].min
        text[start_position...end_position].to_s.squish
      end

      def normalize_for_search(value)
        I18n.transliterate(value.to_s).upcase.gsub(/\s+/, " ")
      end

      def normalized_content(content)
        normalize_for_search(content).first(240)
      end
    end
  end
end
