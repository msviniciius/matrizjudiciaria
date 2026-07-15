class AddSourceTribunalToCaseEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :case_events, :source_tribunal, :string
    add_index :case_events, :source_tribunal
  end
end
