module Pje
  module Ma
    class ImportCaseEventsJob < ApplicationJob
      queue_as :default

      # Realiza a sincronizacao de andamentos para todos os LegalCases ativos
      # que possuem external_number (numero CNJ) configurado.
      #
      # Opcoes:
      #   legal_case_ids: Array de IDs especificos para sincronizar
      #   limit: Maximo de casos a processar (default: 50, para nao sobrecarregar)
      #
      def perform(params = {})
        legal_case_ids = params[:legal_case_ids]
        limit = params[:limit] || 50

        scope = LegalCase.syncable
        scope = scope.where(id: legal_case_ids) if legal_case_ids.present?
        scope = scope.limit(limit)

        total = scope.count
        imported = 0
        skipped = 0
        errors = 0

        Rails.logger.info "[PJE_MA] Iniciando sincronizacao de andamentos para #{total} processos"

        cnj_client = Pje::Cnj::Client.new

        cnj_client.with_persistent_connection do |client|
          scope.find_each do |legal_case|
            Rails.logger.info "[PJE_MA] Processo #{legal_case.internal_number} (#{legal_case.external_number})"

            begin
              count = import_movements_for_case(legal_case, client)
              imported += count[:imported]
              skipped += count[:skipped]
              errors += count[:errors]
            rescue => e
              Rails.logger.error "[PJE_MA] Erro ao processar #{legal_case.external_number}: #{e.message}"
              errors += 1
            end
          end
        end

        Rails.logger.info "[PJE_MA] Sincronizacao concluida: #{imported} importados, #{skipped} ja existentes, #{errors} erros em #{total} processos"

        { imported: imported, skipped: skipped, errors: errors, total: total }
      end

      private

      def import_movements_for_case(legal_case, cnj_client)
        hit = cnj_client.fetch_case(legal_case.external_number)
        return { imported: 0, skipped: 0, errors: 0 } unless hit

        source = hit["_source"] || {}
        movimentos = source["movimentos"] || []
        numero_processo = source["numeroProcesso"]
        tribunal = source["tribunal"] || "TJMA"

        # Atualiza o pje_case_id no LegalCase se ainda nao tiver
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
            Rails.logger.warn "[PJE_MA] Erro ao importar movimento: #{e.message}"
            skipped += 1
          end
        end

        # Atualiza a data da ultima sincronizacao
        legal_case.touch(:last_synced_at)

        { imported: imported, skipped: skipped, errors: 0 }
      end

      def build_pje_id(source)
        source["id"] || "#{source['tribunal']}_#{source['grau']}_#{source['numeroProcesso']}"
      end
    end
  end
end
