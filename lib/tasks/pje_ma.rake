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

      # Permite sobrescrever o tribunal via argumento: rake pje:ma:inspect_cnj[trf1]
      tribunal = ARGV[1] if ARGV[1].present? && !ARGV[1].start_with?("-")

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

    desc "Diagnostica quais tribunais respondem na API CNJ DataJud"
    task diagnose_tribunals: :environment do
      require "net/http"
      require "json"

      base_url = ENV.fetch("CNJ_PJE_BASE_URL", "")
      api_key = ENV.fetch("CNJ_PJE_API_KEY", "")

      if base_url.blank? || api_key.blank?
        puts "ERRO: CNJ_PJE_BASE_URL ou CNJ_PJE_API_KEY nao configurados"
        exit 1
      end

      puts "=" * 72
      puts "Diagnóstico de Tribunais CNJ DataJud"
      puts "Base URL: #{base_url}"
      puts "Data: #{Time.current}"
      puts "=" * 72

      results = { online: [], empty: [], rate_limited: [], timeout: [], offline: [], error: [] }
      total = Office::TRIBUNAL_INTEGRATIONS.count
      tested = 0

      Office::TRIBUNAL_INTEGRATIONS.each do |label, code|
        tested += 1
        print "[#{tested}/#{total}] #{code.upcase}... "

        begin
          uri = URI("#{base_url}/api_publica_#{code}/_search")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 15
          http.read_timeout = 30 # CNJ é lento, alguns tribunais levam 20s+

          request = Net::HTTP::Post.new(uri.path)
          request["Content-Type"] = "application/json"
          request["Authorization"] = "ApiKey #{api_key}"
          request.body = { query: { match_all: {} }, size: 1 }.to_json

          response = http.request(request)

          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            total_hits = data.dig("hits", "total", "value") || 0

            if total_hits > 0
              puts "ONLINE (#{total_hits} processos)"
              results[:online] << { code: code, label: label, hits: total_hits }
            else
              puts "VAZIO (conecta mas sem dados)"
              results[:empty] << { code: code, label: label }
            end
          elsif response.code.to_i == 429
            puts "RATE-LIMITED (HTTP 429 — tente novamente com intervalo maior)"
            results[:rate_limited] << { code: code, label: label }
          else
            puts "OFFLINE (HTTP #{response.code})"
            results[:offline] << { code: code, label: label, code_http: response.code }
          end
        rescue Net::OpenTimeout, Net::ReadTimeout
          puts "TIMEOUT (pode ser rate-limit ou endpoint inexistente)"
          results[:timeout] << { code: code, label: label }
        rescue => e
          puts "ERRO (#{e.message[0..60]})"
          results[:error] << { code: code, label: label, error: e.message }
        end

        # Pausa entre chamadas para evitar rate-limit (HTTP 429)
        # 2s = ~300 chamadas/hora, seguro para a API pública
        sleep 2 unless tested == total
      end

      # Relatório
      puts ""
      puts "=" * 72
      puts "RELATÓRIO FINAL"
      puts "=" * 72

      puts "\n✅ ONLINE (#{results[:online].count} tribunais):"
      results[:online].each { |t| puts "  #{t[:code].upcase} — #{t[:label]} (#{t[:hits]} processos)" }

      puts "\n📭 CONECTA MAS SEM DADOS (#{results[:empty].count} tribunais):"
      results[:empty].each { |t| puts "  #{t[:code].upcase} — #{t[:label]}" }

      puts "\n⏳ RATE-LIMITED (#{results[:rate_limited].count} tribunais):"
      results[:rate_limited].each { |t| puts "  #{t[:code].upcase} — #{t[:label]} (provavelmente funcional)" }

      puts "\n⏱️ TIMEOUT (#{results[:timeout].count} tribunais):"
      results[:timeout].each { |t| puts "  #{t[:code].upcase} — #{t[:label]} (pode nao existir ou rede lenta)" }

      puts "\n❌ OFFLINE (#{results[:offline].count} tribunais):"
      results[:offline].each { |t| puts "  #{t[:code].upcase} — #{t[:label]} (HTTP #{t[:code_http]})" }

      puts "\n⚠️  ERRO (#{results[:error].count} tribunais):"
      results[:error].each { |t| puts "  #{t[:code].upcase} — #{t[:label]} (#{t[:error]})" }

      # Sugere os tribunais funcionalmente confirmados
      functional = results[:online] + results[:rate_limited]
      puts "\nTribunais potencialmente funcionais (#{functional.count}):"
      puts functional.map { |t| t[:code] }.inspect

      # Salva JSON para uso programático
      report_path = Rails.root.join("log/cnj_tribunals_diagnosis.json")
      File.write(report_path, JSON.pretty_generate(results))
      puts "\nRelatório JSON salvo em: #{report_path}"
    end
  end
end
