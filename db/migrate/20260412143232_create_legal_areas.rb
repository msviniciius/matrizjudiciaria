class CreateLegalAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_areas do |t|
      t.string :name, null: false
      t.string :justice_branch, null: false

      t.timestamps
    end

    add_index :legal_areas, [ :justice_branch, :name ], unique: true
  end
end
