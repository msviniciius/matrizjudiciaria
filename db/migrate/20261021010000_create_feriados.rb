class CreateFeriados < ActiveRecord::Migration[8.0]
  def change
    create_table :feriados do |t|
      t.date :data, null: false
      t.string :descricao, null: false
      t.string :ambito, null: false
      t.references :office, foreign_key: true

      t.timestamps
    end

    add_index :feriados, :data
    add_index :feriados, [ :office_id, :data ]
  end
end
