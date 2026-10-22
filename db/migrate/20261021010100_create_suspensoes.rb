class CreateSuspensoes < ActiveRecord::Migration[8.0]
  def change
    create_table :suspensoes do |t|
      t.date :inicio, null: false
      t.date :fim, null: false
      t.string :descricao, null: false
      t.references :office, foreign_key: true

      t.timestamps
    end

    add_index :suspensoes, [ :inicio, :fim ]
    add_index :suspensoes, [ :office_id, :inicio, :fim ]
  end
end
