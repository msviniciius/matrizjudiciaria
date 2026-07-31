class AddOperationalFieldsToUnits < ActiveRecord::Migration[8.1]
  def change
    change_table :units, bulk: true do |t|
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :responsible_name
    end

    add_index :units, :email
  end
end
