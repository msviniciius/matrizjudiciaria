class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :full_name
      t.string :cpf_cnpj
      t.string :rg
      t.date :birth_date
      t.string :marital_status
      t.string :profession
      t.string :phone
      t.string :whatsapp
      t.string :email
      t.string :address
      t.string :city
      t.string :state
      t.string :mother_name
      t.string :father_name
      t.text :notes

      t.timestamps
    end
  end
end
