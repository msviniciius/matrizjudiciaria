class CreateDeadlineSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :deadline_settings do |t|
      t.references :office, null: false, foreign_key: true
      t.string :name, null: false
      t.string :deadline_type, null: false
      t.integer :days_to_due, null: false, default: 0
      t.string :default_priority
      t.text :justification_hint
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :deadline_settings, [ :office_id, :deadline_type ], unique: true
    add_index :deadline_settings, [ :office_id, :active ]
  end
end
