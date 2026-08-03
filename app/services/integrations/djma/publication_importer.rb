module Integrations
  module Djma
    class PublicationImporter
      JOURNAL_NAME = "Diário de Justiça do Estado do Maranhão (DJMA)"

      def initialize(office:, published_on: Date.current, source: nil)
        @office = office
        @published_on = published_on.to_date
        @source = source || PublicationSource.new.fetch
      end

      def call
        return { imported: 0, skipped: 0 } unless office.oab_registration.present? && office.oab_state.present?

        imported = 0
        skipped = 0

        matches.each do |match|
          publication = LegalPublication.find_or_initialize_by(source: "djma", external_id: external_id_for(match))

          if publication.persisted?
            skipped += 1
            next
          end

          publication.assign_attributes(attributes_for(match))
          publication.link_matching_legal_case
          publication.save!
          imported += 1
        end

        { imported: imported, skipped: skipped }
      end

      private

      attr_reader :office, :published_on, :source

      def matches
        @matches ||= PublicationMatcher.new(
          text: source.text,
          oab_registration: office.oab_registration,
          oab_state: office.oab_state,
          process_numbers: office.legal_cases.syncable.pluck(:external_number)
        ).call
      end

      def attributes_for(match)
        {
          office: office,
          event_name: "djma_publication",
          published_at: published_on.beginning_of_day,
          journal_name: JOURNAL_NAME,
          process_number: match[:process_number],
          title: title_for(match),
          content: match[:content],
          raw_payload: {
            provider: "djma",
            source_url: source.url,
            matched_terms: match[:matched_terms],
            published_on: published_on.iso8601
          }
        }
      end

      def title_for(match)
        process_number = match[:process_number].presence
        return "Publicação DJMA do processo #{process_number}" if process_number

        "Publicação DJMA encontrada por OAB"
      end

      def external_id_for(match)
        Digest::SHA256.hexdigest([
          "djma",
          source.url,
          published_on.iso8601,
          LegalPublication.normalize_process_number(match[:process_number]),
          match[:content]
        ].join(":"))
      end
    end
  end
end
