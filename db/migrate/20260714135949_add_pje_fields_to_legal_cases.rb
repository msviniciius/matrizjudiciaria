class AddPjeFieldsToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_cases, :pje_case_id, :string
    add_index :legal_cases, :pje_case_id
    add_column :legal_cases, :last_synced_at, :datetime
    add_index :legal_cases, :last_synced_at
  end
end
