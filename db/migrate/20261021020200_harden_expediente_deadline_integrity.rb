class HardenExpedienteDeadlineIntegrity < ActiveRecord::Migration[8.0]
  def up
    remove_index :deadlines, name: "index_deadlines_on_expediente_id" if connection.indexes(:deadlines).any? { |index| index.name == "index_deadlines_on_expediente_id" }
    add_index :deadlines, :expediente_id, unique: true, name: "index_deadlines_on_expediente_id_unique"
    add_index :expedientes, [ :id, :legal_case_id ], unique: true,
      name: "index_expedientes_on_id_and_legal_case_id"
    remove_foreign_key :deadlines, :expedientes
    add_foreign_key :deadlines, :expedientes,
      column: [ :expediente_id, :legal_case_id ],
      primary_key: [ :id, :legal_case_id ],
      name: "fk_deadlines_expediente_and_legal_case"
  end

  def down
    if foreign_key_exists?(:deadlines, name: "fk_deadlines_expediente_and_legal_case")
      remove_foreign_key :deadlines, name: "fk_deadlines_expediente_and_legal_case"
    end
    remove_index :expedientes, name: "index_expedientes_on_id_and_legal_case_id" if connection.indexes(:expedientes).any? { |index| index.name == "index_expedientes_on_id_and_legal_case_id" }
    add_foreign_key :deadlines, :expedientes unless foreign_key_exists?(:deadlines, :expedientes)
    remove_index :deadlines, name: "index_deadlines_on_expediente_id_unique" if connection.indexes(:deadlines).any? { |index| index.name == "index_deadlines_on_expediente_id_unique" }
    add_index :deadlines, :expediente_id unless connection.indexes(:deadlines).any? { |index| index.name == "index_deadlines_on_expediente_id" }
  end
end
