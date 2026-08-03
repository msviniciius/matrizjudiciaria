class CreateFinancialContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_contracts do |t|
      t.references :office, null: false, foreign_key: true
      t.references :legal_case, null: false, foreign_key: true, index: { unique: true }
      t.decimal :fixed_amount, precision: 12, scale: 2, null: false
      t.boolean :includes_percentage, null: false, default: false
      t.decimal :percentage, precision: 5, scale: 2
      t.string :percentage_basis
      t.decimal :client_received_amount, precision: 12, scale: 2
      t.integer :installment_count, null: false, default: 1
      t.decimal :total_amount, precision: 12, scale: 2, null: false
      t.timestamps
    end

    add_check_constraint :financial_contracts, "fixed_amount > 0", name: "financial_contracts_fixed_amount_positive"
    add_check_constraint :financial_contracts, "total_amount > 0", name: "financial_contracts_total_amount_positive"
    add_check_constraint :financial_contracts,
      "installment_count BETWEEN 1 AND 12",
      name: "financial_contracts_installment_count_range"
    add_check_constraint :financial_contracts,
      "client_received_amount IS NULL OR client_received_amount >= 0",
      name: "financial_contracts_client_received_amount_nonnegative"
    add_check_constraint :financial_contracts,
      "(includes_percentage AND percentage > 0 AND percentage <= 100 AND percentage_basis IN ('claim_value', 'client_received')) OR " \
        "(NOT includes_percentage AND percentage IS NULL AND percentage_basis IS NULL)",
      name: "financial_contracts_percentage_configuration"
  end
end
