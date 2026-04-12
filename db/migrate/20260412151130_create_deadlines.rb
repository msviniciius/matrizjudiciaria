class CreateDeadlines < ActiveRecord::Migration[8.1]
  def change
    create_table :deadlines do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.string :title
      t.string :deadline_type
      t.date :start_date
      t.date :due_date
      t.string :status
      t.string :priority
      t.datetime :completed_at
      t.text :delay_reason
      t.string :responsible_name

      t.timestamps
    end
  end
end
