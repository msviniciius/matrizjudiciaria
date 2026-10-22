class AddExpedienteFieldsToDeadlines < ActiveRecord::Migration[8.0]
  def change
    add_column :deadlines, :protocolo_ref, :string
    add_index :deadlines, :protocolo_ref
  end
end
