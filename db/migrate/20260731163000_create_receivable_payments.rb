class CreateReceivablePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :receivable_payments do |t|
      t.references :receivable, null: false, foreign_key: true
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :paid_at, null: false
      t.string :payment_method
      t.timestamps
    end
  end
end
