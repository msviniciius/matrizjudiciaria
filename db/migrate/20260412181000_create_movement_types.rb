class CreateMovementTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :movement_types do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :movement_types, :code, unique: true
    add_index :movement_types, :name, unique: true
  end
end
