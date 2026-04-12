class CreateCaseEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :case_events do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.string :event_type
      t.datetime :occurred_at
      t.text :description
      t.string :responsible_name

      t.timestamps
    end
  end
end
