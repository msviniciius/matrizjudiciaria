class CreateLegalCases < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_cases do |t|
      t.string :internal_number
      t.string :external_number
      t.date :entry_date
      t.date :protocol_date
      t.string :process_type
      t.string :legal_area
      t.string :subarea
      t.string :main_subject
      t.string :court
      t.string :district
      t.string :phase
      t.string :status
      t.string :responsible_name
      t.string :support_team
      t.string :opposing_party
      t.decimal :claim_value
      t.string :priority
      t.text :strategic_notes
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
