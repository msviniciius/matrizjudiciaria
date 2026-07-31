class AddOutcomeNotesToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_cases, :outcome_date, :date
    add_column :legal_cases, :outcome_notes, :text
  end
end
