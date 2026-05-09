class RemoveEventFieldsFromCaseEvents < ActiveRecord::Migration[8.1]
  def change
    remove_index :case_events, :occurred_at if index_exists?(:case_events, :occurred_at)
    remove_column :case_events, :event_type, :string if column_exists?(:case_events, :event_type)
    remove_column :case_events, :occurred_at, :datetime if column_exists?(:case_events, :occurred_at)
  end
end
