class AddAdministrativeSituationToProcessMovements < ActiveRecord::Migration[8.0]
  def change
    add_column :process_movements, :administrative_situation, :string
    add_index :process_movements, :administrative_situation
  end
end
