class AddDadosGovToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :dados_gov, :text
  end
end
