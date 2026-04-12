class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.date :due_date
      t.string :responsible_name

      t.timestamps
    end
  end
end
