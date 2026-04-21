class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @clients = current_office.clients.ordered.includes(:legal_cases)
  end

  def show
    @client_legal_cases = @client.legal_cases.order(updated_at: :desc)
  end

  def new
    @client = current_office.clients.new
  end

  def edit
  end

  def create
    @client = current_office.clients.new(client_params)

    respond_to do |format|
      if @client.save
        format.html { redirect_to @client, notice: "Cliente cadastrado com sucesso." }
        format.json { render :show, status: :created, location: @client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def quick_create
    @client = current_office.clients.new(quick_client_params.merge(cadastro_pendente: true))

    if @client.save(context: :quick_create)
      render json: {
        id: @client.id,
        full_name: @client.full_name,
        display_name: @client.display_name_with_status,
        cadastro_pendente: @client.cadastro_pendente
      }, status: :created
    else
      render json: { errors: @client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: "Cliente atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @client.destroy!

    respond_to do |format|
      format.html { redirect_to clients_path, notice: "Cliente excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_client
    @client = current_office.clients.find(params.expect(:id))
  end

  def client_params
    params.expect(client: [
      :full_name,
      :cpf_cnpj,
      :rg,
      :birth_date,
      :marital_status,
      :profession,
      :phone,
      :whatsapp,
      :email,
      :address,
      :city,
      :state,
      :mother_name,
      :father_name,
      :notes,
      :dados_gov,
      :zip_code,
      :cadastro_pendente
    ])
  end

  def quick_client_params
    params.expect(client: [ :full_name, :cpf_cnpj, :phone, :whatsapp, :email, :dados_gov ])
  end
end
