class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :courts, :name, unique: true
  end
end
