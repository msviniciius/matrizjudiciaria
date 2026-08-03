class CreateFinancialInstallments < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_installments do |t|
      t.references :financial_contract, null: false, foreign_key: true
      t.integer :number, null: false
      t.date :due_date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :financial_installments,
      [ :financial_contract_id, :number ],
      unique: true,
      name: "index_financial_installments_on_contract_and_number"
    add_index :financial_installments, :due_date
    add_index :financial_installments, :status
    add_check_constraint :financial_installments, "number BETWEEN 1 AND 12", name: "financial_installments_number_range"
    add_check_constraint :financial_installments, "amount > 0", name: "financial_installments_amount_positive"
    add_check_constraint :financial_installments,
      "status IN ('pending', 'paid')",
      name: "financial_installments_status_allowed"
  end
end
