class CreateUnitsAndUserUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :office, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :units, [:office_id, :name], unique: true
    add_index :units, [:office_id, :slug], unique: true

    create_table :user_units do |t|
      t.references :user, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_units, [:user_id, :unit_id], unique: true

    add_reference :clients, :unit, foreign_key: true
    add_reference :legal_cases, :unit, foreign_key: true
  end
end
