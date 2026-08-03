class CreateLegalPublications < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_publications do |t|
      t.references :office, null: false, foreign_key: true
      t.references :legal_case, foreign_key: true
      t.string :source, null: false, default: "escavador"
      t.string :external_id, null: false
      t.string :event_name, null: false
      t.datetime :published_at
      t.string :court_name
      t.string :journal_name
      t.string :process_number
      t.string :title
      t.text :content, null: false
      t.jsonb :raw_payload, null: false, default: {}
      t.datetime :read_at

      t.timestamps
    end

    add_index :legal_publications, [ :source, :external_id ], unique: true
    add_index :legal_publications, [ :office_id, :read_at ]
    add_index :legal_publications, [ :office_id, :legal_case_id ]
    add_index :legal_publications, :process_number
  end
end
