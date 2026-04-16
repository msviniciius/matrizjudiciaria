class AddCadastroPendenteToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :cadastro_pendente, :boolean, null: false, default: false
    add_index :clients, :cadastro_pendente
  end
end
