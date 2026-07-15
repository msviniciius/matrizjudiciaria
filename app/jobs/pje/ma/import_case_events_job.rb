module Pje
  module Ma
    class ImportCaseEventsJob < ApplicationJob
      queue_as :default

      # Sincroniza andamentos do CNJ DataJud para processos ativos.
      #
      # Parâmetros:
      #   office_id:       ID do escritório (usa enabled_tribunals do office)
      #   tribunal:        Código do tribunal (ex: "tjma", "trf1")
      #   legal_case_ids:  Array de IDs específicos para sincronizar
      #   limit:           Máximo de casos por tribunal (default: 50)
      #
      # Comportamento:
      #   - Se office_id informado: sincroniza apenas tribunais habilitados daquele office
      #   - Se tribunal informado: sincroniza apenas aquele tribunal
      #   - Se nenhum: itera todos os offices e seus tribunais habilitados
      #   - Fallback: se nenhum office tiver tribunais, usa ENV["CNJ_PJE_TRIBUNAL_ALIAS"]
      #
      def perform(params = {})
        office_id = params[:office_id]
        tribunal_filter = params[:tribunal]
        legal_case_ids = params[:legal_case_ids]
        limit = params[:limit] || 50

        offices = resolve_offices(office_id)
        total_imported = 0
        total_skipped = 0
        total_errors = 0

        offices.find_each do |office|
          tribunals = resolve_tribunals(office, tribunal_filter)

          tribunals.each do |tribunal_code|
            result = import_for_tribunal(office, tribunal_code, legal_case_ids, limit)
            total_imported += result[:imported]
            total_skipped += result[:skipped]
            total_errors += result[:errors]
          end
        end

        Rails.logger.info "[PJE] Sincronização concluída: #{total_imported} importados, " \
                          "#{total_skipped} já existentes, #{total_errors} erros"

        { imported: total_imported, skipped: total_skipped, errors: total_errors }
      end

      private

      def resolve_offices(office_id)
        if office_id.present?
          Office.where(id: office_id)
        else
          Office.all
        end
      end

      def resolve_tribunals(office, tribunal_filter)
        if tribunal_filter.present?
          [tribunal_filter]
        elsif office.enabled_tribunal_codes.any?
          office.enabled_tribunal_codes
        else
          # Fallback para single-tenant: usa ENV
          [ENV.fetch("CNJ_PJE_TRIBUNAL_ALIAS", "tjma")]
        end
      end

      def import_for_tribunal(office, tribunal_code, legal_case_ids, limit)
        scope = office.legal_cases.syncable
        scope = scope.where(id: legal_case_ids) if legal_case_ids.present?
        scope = scope.limit(limit)

        total = scope.count
        return { imported: 0, skipped: 0, errors: 0 } if total.zero?

        Rails.logger.info "[PJE] #{office.name} / #{tribunal_code.upcase}: #{total} processos"

        cnj_client = Pje::Cnj::Client.new(tribunal: tribunal_code)
        imported = 0
        skipped = 0
        errors = 0

        cnj_client.with_persistent_connection do |client|
          scope.find_each do |legal_case|
            begin
              count = import_movements_for_case(legal_case, client, office)
              imported += count[:imported]
              skipped += count[:skipped]
              errors += count[:errors]
            rescue => e
              Rails.logger.error "[PJE] Erro #{legal_case.external_number}: #{e.message}"
              errors += 1
            end
          end
        end

        { imported: imported, skipped: skipped, errors: errors }
      end

      def import_movements_for_case(legal_case, cnj_client, office = nil)
        hit = cnj_client.fetch_case(legal_case.external_number)
        return { imported: 0, skipped: 0, errors: 0 } unless hit

        source = hit["_source"] || {}
        movimentos = source["movimentos"] || []
        numero_processo = source["numeroProcesso"]
        tribunal = source["tribunal"] || cnj_client.tribunal.upcase

        # Atualiza pje_case_id no LegalCase se ainda não tiver
        pje_id = build_pje_id(source)
        legal_case.update_column(:pje_case_id, pje_id) if legal_case.pje_case_id.blank? && pje_id.present?

        imported = 0
        skipped = 0

        movimentos.each do |movimento|
          begin
            normalizer = Integrations::Normalizers::PjeMaCaseEventNormalizer.new(
              movement_hash: movimento,
              legal_case_id: legal_case.id,
              numero_processo: numero_processo,
              tribunal: tribunal
            )

            attrs = normalizer.call
            CaseEvent.create!(attrs)
            imported += 1
          rescue ActiveRecord::RecordNotUnique
            skipped += 1
          rescue => e
            Rails.logger.warn "[PJE] Erro ao importar movimento: #{e.message}"
            skipped += 1
          end
        end

        # Atualiza a data da última sincronização
        legal_case.touch(:last_synced_at)

        { imported: imported, skipped: skipped, errors: 0 }
      end

      def build_pje_id(source)
        source["id"] || "#{source['tribunal']}_#{source['grau']}_#{source['numeroProcesso']}"
      end
    end
  end
end
