class CreateReceivables < ActiveRecord::Migration[8.1]
  def change
    create_table :receivables do |t|
      t.references :office, null: false, foreign_key: true
      t.references :unit, foreign_key: true
      t.references :client, foreign_key: true
      t.references :legal_case, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :amount_paid, precision: 12, scale: 2, null: false, default: 0
      t.date :due_date
      t.date :paid_at
      t.string :payment_method
      t.text :notes
      t.string :trigger, null: false, default: "manual"
      t.datetime :triggered_at
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :receivables, :status
    add_index :receivables, :due_date
  end
end
