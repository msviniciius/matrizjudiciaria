class AddExtensionTrackingToDeadlines < ActiveRecord::Migration[8.1]
  def change
    add_column :deadlines, :extended_at, :datetime
    add_column :deadlines, :extended_from_date, :date
    add_index :deadlines, :extended_at
  end
end
