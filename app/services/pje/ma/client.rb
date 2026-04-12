module Pje
  module Ma
    class Client < Pje::BaseClient
      def initialize
        super(
          base_url: ENV.fetch("PJE_MA_BASE_URL", ""),
          access_token: ENV.fetch("PJE_MA_ACCESS_TOKEN", "")
        )
      end

      def fetch_processes(params = {})
        path = ENV.fetch("PJE_MA_PROCESSOS_PATH", "")
        raise ConfigurationError, "PJE_MA_PROCESSOS_PATH ausente" if path.strip.empty?

        get(path, params: params)
      end

      def fetch_case_events(params = {})
        path = ENV.fetch("PJE_MA_ANDAMENTOS_PATH", "")
        raise ConfigurationError, "PJE_MA_ANDAMENTOS_PATH ausente" if path.strip.empty?

        get(path, params: params)
      end

      def fetch_deadlines(params = {})
        path = ENV.fetch("PJE_MA_PRAZOS_PATH", "")
        raise ConfigurationError, "PJE_MA_PRAZOS_PATH ausente" if path.strip.empty?

        get(path, params: params)
      end
    end
  end
end
