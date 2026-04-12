module Pje
  module Ma
    class Importer
      def initialize(client: Client.new)
        @client = client
      end

      def import_processes(params: {})
        payload = @client.fetch_processes(params)
        normalize_collection(payload)
      end

      def import_case_events(params: {})
        payload = @client.fetch_case_events(params)
        normalize_collection(payload)
      end

      def import_deadlines(params: {})
        payload = @client.fetch_deadlines(params)
        normalize_collection(payload)
      end

      private

      def normalize_collection(payload)
        if payload.is_a?(Hash)
          payload["items"] || payload["content"] || payload["data"] || []
        elsif payload.is_a?(Array)
          payload
        else
          []
        end
      end
    end
  end
end
