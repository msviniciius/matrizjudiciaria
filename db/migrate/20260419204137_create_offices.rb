class CreateOffices < ActiveRecord::Migration[8.1]
  def change
    create_table :offices do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :offices, :slug, unique: true
  end
end
