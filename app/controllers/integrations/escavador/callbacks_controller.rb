module Integrations
  module Escavador
    class CallbacksController < ActionController::Base
      protect_from_forgery with: :null_session

      def create
        return head :unauthorized unless authorized?

        normalizer = PublicationNormalizer.new(callback_payload)
        return head :accepted unless normalizer.supported?

        attributes = normalizer.call
        office = office_for_callback
        return head :unprocessable_entity if office.blank?

        publication = LegalPublication.find_or_initialize_by(
          source: attributes[:source],
          external_id: attributes[:external_id]
        )
        return head :ok if publication.persisted?

        publication.assign_attributes(attributes.merge(office: office))
        publication.link_matching_legal_case
        publication.save!

        head :created
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger.error("[Escavador] callback invalido: #{error.record.errors.full_messages.to_sentence}")
        head :unprocessable_entity
      end

      private

      def callback_payload
        request.request_parameters.deep_stringify_keys
      end

      def authorized?
        expected_token = ENV["ESCAVADOR_CALLBACK_TOKEN"].to_s
        return false if expected_token.blank?

        expected_header = "Bearer #{expected_token}"
        actual_header = request.authorization.to_s
        actual_header.bytesize == expected_header.bytesize &&
          ActiveSupport::SecurityUtils.secure_compare(actual_header, expected_header)
      end

      def office_for_callback
        Office
          .where.not(oab_registration: [ nil, "" ])
          .where.not(oab_state: [ nil, "" ])
          .order(:id)
          .first
      end
    end
  end
end
