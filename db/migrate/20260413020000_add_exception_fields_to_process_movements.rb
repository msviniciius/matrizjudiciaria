class AddExceptionFieldsToProcessMovements < ActiveRecord::Migration[8.1]
  def change
    add_column :process_movements, :manual_override, :boolean, null: false, default: false
    add_column :process_movements, :exception_authorized, :boolean, null: false, default: false
    add_column :process_movements, :override_reason, :text
    add_column :process_movements, :override_by_user_id, :bigint

    add_index :process_movements, :manual_override
    add_index :process_movements, :override_by_user_id
  end
end
