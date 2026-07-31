class AddMatrixAccessToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :matrix_access, :boolean, null: false, default: true
  end
end
