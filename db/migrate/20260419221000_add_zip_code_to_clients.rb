class AddZipCodeToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :zip_code, :string
    add_index :clients, :zip_code
  end
end
