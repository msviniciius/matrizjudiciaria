class AddEnabledTribunalsToOffices < ActiveRecord::Migration[8.1]
  def change
    add_column :offices, :enabled_tribunals, :string, array: true, default: [], null: false
    add_index :offices, :enabled_tribunals, using: :gin
  end
end
