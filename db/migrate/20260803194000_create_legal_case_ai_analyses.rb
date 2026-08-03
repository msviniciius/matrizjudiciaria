class CreateLegalCaseAiAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_case_ai_analyses do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.string :provider, null: false
      t.string :model, null: false
      t.text :summary, null: false
      t.jsonb :risks, null: false, default: []
      t.text :suggested_action, null: false
      t.string :confidence, null: false, default: "low"
      t.text :notes
      t.jsonb :deterministic_snapshot, null: false, default: {}
      t.jsonb :raw_response, null: false, default: {}
      t.timestamps
    end

    add_index :legal_case_ai_analyses, [ :legal_case_id, :created_at ]
    add_index :legal_case_ai_analyses, [ :provider, :model ]
  end
end
