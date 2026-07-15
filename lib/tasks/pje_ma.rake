require "net/http"
require "json"
require "pp"

namespace :pje do
  namespace :ma do
    desc "Inspecionar resposta da API CNJ DataJud (fonte real)"
    task inspect_cnj: :environment do
      log_path = Rails.root.join("log/cnj_datajud_inspect.log")
      logger = Logger.new(log_path)
      logger.formatter = ->(severity, datetime, _progname, msg) { "[#{datetime}] #{severity}: #{msg}\n" }

      def log_and_print(msg, logger)
        puts msg
        logger.info(msg)
      end

      log_and_print("=== Inspecionando API CNJ DataJud ===", logger)
      log_and_print("Data/Hora: #{Time.current}", logger)

      base_url = ENV.fetch("CNJ_PJE_BASE_URL", "")
      api_key = ENV.fetch("CNJ_PJE_API_KEY", "")
      tribunal = ENV.fetch("CNJ_PJE_TRIBUNAL_ALIAS", "tjma")

      log_and_print("BASE_URL: #{base_url}", logger)
      log_and_print("TRIBUNAL: #{tribunal}", logger)
      log_and_print("API_KEY presente: #{api_key.present?}", logger)

      if base_url.blank? || api_key.blank?
        log_and_print("ERRO: CNJ_PJE_BASE_URL ou CNJ_PJE_API_KEY nao configurados no .env", logger)
        next
      end

      begin
        # Endpoint correto: api_publica_{TRIBUNAL}/_search
        endpoint = "#{base_url}/api_publica_#{tribunal}/_search"
        uri = URI(endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 30

        # Buscar processos do TJMA com movimentos, ordenados por data de atualizacao
        query = {
          query: {
            match_all: {}
          },
          size: 5,
          sort: [
            { dataHoraUltimaAtualizacao: { order: "desc" } }
          ]
        }

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "ApiKey #{api_key}"
        request.body = query.to_json

        log_and_print("\n--- Buscando processos do #{tribunal.upcase} ---", logger)
        log_and_print("POST #{endpoint}", logger)
        log_and_print("Body: #{query.to_json}", logger)

        response = http.request(request)

        log_and_print("Status: #{response.code} #{response.message}", logger)

        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)

          # Salvar resposta completa
          json_path = Rails.root.join("log/cnj_datajud_sample.json")
          File.write(json_path, JSON.pretty_generate(data))
          log_and_print("\nJSON completo salvo em: #{json_path}", logger)

          # Analisar estrutura
          hits = data.dig("hits", "hits") || []
          total = data.dig("hits", "total", "value") || 0
          log_and_print("Total de processos encontrados: #{total}", logger)
          log_and_print("Retornados nesta pagina: #{hits.length}", logger)

          hits.each_with_index do |hit, i|
            source = hit["_source"] || {}
            log_and_print("\n--- Processo #{i + 1}: #{source['numeroProcesso']} ---", logger)
            log_and_print("Classe: #{source.dig('classe', 'nome')}", logger)
            log_and_print("Sistema: #{source.dig('sistema', 'nome')}", logger)
            log_and_print("Grau: #{source['grau']}", logger)
            log_and_print("Ultima atualizacao: #{source['dataHoraUltimaAtualizacao']}", logger)
            log_and_print("Ajuizamento: #{source['dataAjuizamento']}", logger)
            log_and_print("Orgao Julgador: #{source.dig('orgaoJulgador', 'nome')}", logger)

            movimentos = source["movimentos"] || []
            log_and_print("  Movimentos (#{movimentos.length}):", logger)
            movimentos.first(5).each do |mov|
              log_and_print("    - [#{mov['dataHora']}] #{mov['codigo']} #{mov['nome']}", logger)
              complementos = mov["complementosTabelados"] || []
              complementos.each do |comp|
                log_and_print("      complemento: #{comp['nome']}: #{comp['valor'] || comp['descricao']}", logger)
              end
            end
            log_and_print("    ... (mostrando 5 de #{movimentos.length})", logger) if movimentos.length > 5
          end

          # Salvar apenas movimentos do primeiro processo para analise detalhada
          if hits.any?
            primeiro = hits.first["_source"]
            movimentos = primeiro["movimentos"] || []
            mov_json_path = Rails.root.join("log/cnj_datajud_movimentos_sample.json")
            File.write(mov_json_path, JSON.pretty_generate(movimentos))
            log_and_print("\nMovimentos do primeiro processo salvos em: #{mov_json_path}", logger)
          end
        else
          log_and_print("ERRO na busca: #{response.code}", logger)
          log_and_print(response.body.to_s[0..1000], logger)
        end
      rescue => e
        log_and_print("ERRO: #{e.class}: #{e.message}", logger)
        log_and_print(e.backtrace.first(10).join("\n"), logger)
      end

      log_and_print("\nLog completo salvo em: #{log_path}", logger)
    end
  end
end
