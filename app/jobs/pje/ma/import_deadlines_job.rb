module Pje
  module Ma
    class ImportDeadlinesJob < ApplicationJob
      queue_as :default

      def perform(params = {})
        importer = Importer.new
        items = importer.import_deadlines(params: params)

        # TODO: mapear campos do PJe para Deadline
        items.each do |_item|
          # placeholder
        end
      end
    end
  end
end
