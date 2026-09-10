class AddOabStateToOffices < ActiveRecord::Migration[8.0]
  def change
    add_column :offices, :oab_state, :string, limit: 2
  end
end
