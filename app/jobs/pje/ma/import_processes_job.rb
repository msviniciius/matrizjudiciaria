module Pje
  module Ma
    class ImportProcessesJob < ApplicationJob
      queue_as :default

      def perform(params = {})
        importer = Importer.new
        items = importer.import_processes(params: params)

        # TODO: mapear campos do PJe para LegalCase e Client
        # Exemplo de estrutura esperada por item:
        # { "numeroProcesso" => "...", "classe" => "...", "partes" => [...] }
        items.each do |_item|
          # placeholder
        end
      end
    end
  end
end
