module Integrations
  module Djma
    class ImportPublicationsJob < ApplicationJob
      queue_as :default

      def perform(params = {})
        published_on = params[:published_on].present? ? Date.parse(params[:published_on].to_s) : Date.current
        offices = resolve_offices(params[:office_id])
        totals = { imported: 0, skipped: 0, errors: 0 }
        office_count = offices.count
        log_info "Iniciando importação de publicações published_on=#{published_on.iso8601} offices=#{office_count}"
        return totals.tap { log_totals(_1) } if office_count.zero?

        source = params[:source] || PublicationSource.new.fetch
        log_info "Fonte carregada fonte=#{source.url} chars=#{source.text.to_s.length}"

        offices.find_each do |office|
          result = PublicationImporter.new(office: office, published_on: published_on, source: source).call
          totals[:imported] += result[:imported]
          totals[:skipped] += result[:skipped]
          log_info "Escritório #{office.id} processado imported=#{result[:imported]} skipped=#{result[:skipped]}"
        rescue => error
          Rails.logger.error "[DJMA] Erro ao importar publicações do escritório #{office.id}: #{error.message}"
          totals[:errors] += 1
        end

        totals.tap { log_totals(_1) }
      end

      private

      def resolve_offices(office_id)
        scope = Office.where.not(oab_registration: [ nil, "" ]).where.not(oab_state: [ nil, "" ])
        office_id.present? ? scope.where(id: office_id) : scope
      end

      def log_info(message)
        Rails.logger.info "[DJMA] #{message}"
      end

      def log_totals(totals)
        log_info "Importação finalizada imported=#{totals[:imported]} skipped=#{totals[:skipped]} errors=#{totals[:errors]}"
      end
    end
  end
end
