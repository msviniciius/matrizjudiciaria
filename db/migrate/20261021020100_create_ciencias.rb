class CreateCiencias < ActiveRecord::Migration[8.0]
  def change
    create_table :ciencias do |t|
      t.references :expediente, null: false, foreign_key: true, index: false
      t.references :user, foreign_key: true
      t.string :tipo, null: false
      t.date :data_ciencia, null: false

      t.timestamps
    end

    add_index :ciencias, :expediente_id, unique: true
  end
end
