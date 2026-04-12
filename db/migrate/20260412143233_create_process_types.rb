class CreateProcessTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :process_types do |t|
      t.string :name, null: false
      t.references :legal_area, null: false, foreign_key: true

      t.timestamps
    end

    add_index :process_types, [:legal_area_id, :name], unique: true
  end
end
