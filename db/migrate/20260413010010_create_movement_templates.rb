class CreateMovementTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :movement_templates do |t|
      t.references :phase, null: false, foreign_key: { to_table: :process_phases }
      t.references :movement_type, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.text :short_description
      t.string :nature_default, null: false
      t.string :impact_default, null: false
      t.boolean :updates_phase, null: false, default: false
      t.references :next_phase, null: true, foreign_key: { to_table: :process_phases }
      t.boolean :creates_task, null: false, default: false
      t.string :task_template_name
      t.boolean :creates_deadline, null: false, default: false
      t.string :deadline_template_name
      t.boolean :requires_exam_id, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :order, null: false, default: 0

      t.timestamps
    end

    add_index :movement_templates, :code, unique: true
    add_index :movement_templates, [ :phase_id, :active, :order ]
    add_index :movement_templates, [ :movement_type_id, :active ]
  end
end
