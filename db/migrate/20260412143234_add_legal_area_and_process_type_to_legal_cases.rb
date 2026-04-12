class AddLegalAreaAndProcessTypeToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_reference :legal_cases, :legal_area, foreign_key: true
    add_reference :legal_cases, :process_type, foreign_key: true
  end
end
