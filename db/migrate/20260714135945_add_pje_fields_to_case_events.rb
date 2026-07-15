class AddPjeFieldsToCaseEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :case_events, :pje_external_id, :string
    add_index :case_events, :pje_external_id, unique: true, where: "pje_external_id IS NOT NULL"
    add_column :case_events, :event_date, :datetime
    add_index :case_events, :event_date
  end
end
