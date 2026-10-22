class CreateExpedientes < ActiveRecord::Migration[8.0]
  def change
    create_table :expedientes do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.string :tipo, null: false
      t.text :descricao, null: false
      t.date :data_disponibilizacao, null: false
      t.integer :quantidade_dias, null: false
      t.string :contagem, null: false
      t.boolean :prazo_em_dobro, null: false, default: false
      t.string :origem, null: false
      t.string :referencia_externa
      t.string :referencia_evento

      t.timestamps
    end

    add_index :expedientes, [ :legal_case_id, :referencia_externa ], unique: true,
      where: "referencia_externa IS NOT NULL"
    add_reference :deadlines, :expediente, foreign_key: true
  end
end
