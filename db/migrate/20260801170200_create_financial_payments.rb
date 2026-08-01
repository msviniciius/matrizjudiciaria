class CreateFinancialPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_payments do |t|
      t.references :financial_installment, null: false, foreign_key: true, index: { unique: true }
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.datetime :paid_at, null: false
      t.string :payment_method, null: false
      t.timestamps
    end

    add_check_constraint :financial_payments, "amount > 0", name: "financial_payments_amount_positive"
    add_check_constraint :financial_payments,
      "payment_method IN ('pix', 'cash', 'credit_card', 'debit_card')",
      name: "financial_payments_method_allowed"
  end
end
