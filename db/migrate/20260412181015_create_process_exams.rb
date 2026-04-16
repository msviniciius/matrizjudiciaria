class CreateProcessExams < ActiveRecord::Migration[8.1]
  def change
    create_table :process_exams do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.string :exam_nature, null: false
      t.string :exam_scope, null: false
      t.string :status, null: false, default: "nao_designada"
      t.datetime :scheduled_at
      t.string :location
      t.string :expert_name
      t.text :notes
      t.bigint :created_by_user_id
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :process_exams, [ :legal_case_id, :active ]
    add_index :process_exams, :status
    add_index :process_exams, :scheduled_at
  end
end
