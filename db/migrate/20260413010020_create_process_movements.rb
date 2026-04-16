class CreateProcessMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :process_movements do |t|
      t.references :process, null: false, foreign_key: { to_table: :legal_cases }
      t.references :phase, null: false, foreign_key: { to_table: :process_phases }
      t.references :movement_type, null: false, foreign_key: true
      t.references :movement_template, null: true, foreign_key: true
      t.references :exam, null: true, foreign_key: { to_table: :process_exams }
      t.datetime :event_date, null: false
      t.string :display_title, null: false
      t.text :complementary_description
      t.string :nature, null: false
      t.string :impact, null: false
      t.string :origin, null: false
      t.boolean :updates_phase, null: false, default: false
      t.references :next_phase, null: true, foreign_key: { to_table: :process_phases }
      t.boolean :creates_task, null: false, default: false
      t.boolean :creates_deadline, null: false, default: false
      t.bigint :created_by_user_id
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :process_movements, [ :process_id, :event_date ]
    add_index :process_movements, [ :active, :event_date ]
    add_index :process_movements, [ :movement_type_id, :event_date ]
  end
end
