class AddOutcomeToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_cases, :outcome, :string, null: false, default: "undefined"
    add_column :legal_cases, :outcome_confirmed_at, :datetime
    add_reference :legal_cases, :outcome_confirmed_by, foreign_key: { to_table: :users }
    add_index :legal_cases, :outcome
  end
end
