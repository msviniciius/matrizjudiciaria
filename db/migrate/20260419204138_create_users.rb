class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :office, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, null: false, default: "attendant"
      t.string :password_digest, null: false
      t.string :password_salt, null: false
      t.boolean :active, null: false, default: true
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, [ :office_id, :email ], unique: true
  end
end
