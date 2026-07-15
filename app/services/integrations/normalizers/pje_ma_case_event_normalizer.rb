module Integrations
  module Normalizers
    class PjeMaCaseEventNormalizer
      # Mapeia um movimento do CNJ DataJud para atributos do CaseEvent.
      #
      # Estrutura esperada do movimento (CNJ DataJud):
      # {
      #   "codigo" => 1051,
      #   "dataHora" => "2026-02-07T01:08:49.000Z",
      #   "nome" => "Decurso de Prazo",
      #   "complementosTabelados" => [{ "codigo" => 3, "nome" => "para despacho", ... }],
      #   "orgaoJulgador" => { "codigo" => "3134", "nome" => "..." }
      # }
      #
      def initialize(movement_hash:, legal_case_id:, numero_processo:, tribunal: "TJMA")
        @movement = movement_hash
        @legal_case_id = legal_case_id
        @numero_processo = numero_processo
        @tribunal = tribunal
      end

      def call
        {
          pje_external_id: build_external_id,
          legal_case_id: @legal_case_id,
          description: build_description,
          event_date: parse_event_date,
          entry_kind: "andamento",
          source_tribunal: @tribunal,
          movement_type_id: find_movement_type_id,
          next_action: extract_next_action,
          responsible_name: nil # CNJ nao fornece responsavel diretamente
        }
      end

      private

      def build_external_id
        codigo = @movement["codigo"]
        data = @movement["dataHora"]
        "#{@numero_processo}_#{codigo}_#{data}"
      end

      def build_description
        nome = @movement["nome"] || "Andamento sem descricao"
        complementos = @movement["complementosTabelados"] || []

        if complementos.any?
          detalhes = complementos.map { |c| "#{c['nome']}: #{c['valor'] || c['descricao']}" }.join(" | ")
          "#{nome} (#{detalhes})"
        else
          nome
        end
      end

      def parse_event_date
        DateTime.parse(@movement["dataHora"])
      rescue
        nil
      end

      def find_movement_type_id
        codigo = @movement["codigo"].to_i
        nome = @movement["nome"] || ""

        # Busca primeiro pelo codigo CNJ mapeado
        mapped_code = CNJ_CODE_MAPPING[codigo]
        return MovementType.find_by(code: mapped_code)&.id if mapped_code

        # Tenta buscar pelo nome do movimento
        MovementType.where("name ILIKE ?", "%#{nome}%").pick(:id)
      end

      # Mapeamento de codigos CNJ → codigos internos de MovementType
      CNJ_CODE_MAPPING = {
        # Distribuicao / Inicio
        26 => "protocolo_judicial",
        # Peticoes
        85 => "movimentacao_judicial",
        # Conclusao
        51 => "analise_juridica",
        # Despacho / Decisao
        220 => "decisao",     # Improcedencia
        219 => "decisao",     # Procedencia
        471 => "decisao",     # Sentenca
        # Audiencia
        12740 => "audiencia", # Conciliacao
        12750 => "audiencia", # Instrucao e Julgamento
        # Provas / Pericia
        1051 => "movimentacao_judicial", # Decurso de Prazo
        # Publicacoes
        92 => "movimentacao_judicial",   # Publicacao
        1061 => "movimentacao_judicial", # Disponibilizacao DJE
        # Recursos
        848 => "recurso",     # Transito em julgado
        # Encerramento
        246 => "encerramento", # Definitivo
        22 => "encerramento",  # Baixa definitiva
        # Execucao
        11010 => "execucao"    # Mero expediente
      }.freeze

      def extract_next_action
        nome = @movement["nome"] || ""

        # Movimentos que tipicamente exigem providencia do escritorio
        providencia_keywords = %w[
          Intimação Citação Notificação Manifestação Impugnação
          Contestação Réplica Esclarecimento Diligência
          Petição Emenda Complementação Juntada
        ]

        if providencia_keywords.any? { |kw| nome.include?(kw) }
          complementos = @movement["complementosTabelados"] || []
          prazo = complementos.find { |c| c["descricao"]&.include?("prazo") }
          if prazo
            "Providenciar #{nome.downcase} - Prazo: #{prazo['valor'] || prazo['nome']}"
          else
            "Providenciar #{nome.downcase}"
          end
        end
      end
    end
  end
end
