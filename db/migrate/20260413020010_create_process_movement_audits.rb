class CreateProcessMovementAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :process_movement_audits do |t|
      t.references :process_movement, null: false, foreign_key: true
      t.string :action, null: false
      t.jsonb :changed_fields, null: false, default: {}
      t.text :justification
      t.bigint :changed_by_user_id
      t.timestamps
    end

    add_index :process_movement_audits, :action
    add_index :process_movement_audits, :changed_by_user_id
    add_index :process_movement_audits, :created_at
  end
end
