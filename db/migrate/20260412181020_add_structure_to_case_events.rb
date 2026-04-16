class AddStructureToCaseEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :case_events, :movement_type, foreign_key: true
    add_column :case_events, :entry_kind, :string, null: false, default: "andamento"
    add_column :case_events, :next_action, :string
    add_column :case_events, :phase_after, :string
    add_column :case_events, :status_after, :string
    add_reference :case_events, :process_exam, foreign_key: true

    add_index :case_events, :entry_kind
    add_index :case_events, :occurred_at
  end
end
