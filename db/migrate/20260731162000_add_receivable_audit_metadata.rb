class AddReceivableAuditMetadata < ActiveRecord::Migration[8.1]
  def change
    add_reference :receivables, :payment_recorded_by, foreign_key: { to_table: :users }
    add_column :receivables, :payment_recorded_at, :datetime
    add_reference :receivables, :canceled_by, foreign_key: { to_table: :users }
    add_column :receivables, :canceled_at, :datetime
  end
end
