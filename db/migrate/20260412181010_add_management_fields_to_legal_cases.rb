class AddManagementFieldsToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_cases, :last_movement, :text
    add_column :legal_cases, :last_movement_at, :datetime
    add_column :legal_cases, :next_action, :string
    add_column :legal_cases, :next_deadline_on, :date
    add_column :legal_cases, :tem_pericia, :boolean, null: false, default: false
    add_column :legal_cases, :observacao_geral_pericia, :text
  end
end
