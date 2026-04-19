class AddZipCodeToOffices < ActiveRecord::Migration[8.1]
  def change
    add_column :offices, :zip_code, :string
    add_index :offices, :zip_code
  end
end
