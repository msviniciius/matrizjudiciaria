module Pje
  module Ma
    class ImportCaseEventsJob < ApplicationJob
      queue_as :default

      def perform(params = {})
        importer = Importer.new
        items = importer.import_case_events(params: params)

        # TODO: mapear campos do PJe para CaseEvent
        items.each do |_item|
          # placeholder
        end
      end
    end
  end
end
