class AddFinancialContractMigrationFlagToReceivables < ActiveRecord::Migration[8.1]
  def change
    add_column :receivables, :migrated_to_financial_contract, :boolean, null: false, default: false
    add_index :receivables, :migrated_to_financial_contract
  end
end
