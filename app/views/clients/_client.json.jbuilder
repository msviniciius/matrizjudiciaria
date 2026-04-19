json.extract! client, :id, :full_name, :cpf_cnpj, :rg, :birth_date, :marital_status, :profession, :phone, :whatsapp, :email, :zip_code, :address, :city, :state, :mother_name, :father_name, :notes, :created_at, :updated_at
json.url client_url(client, format: :json)
