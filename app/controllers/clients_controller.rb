class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @filters = client_filters
    scope = scope_by_current_unit(current_office.clients).ordered.includes(:legal_cases)

    if @filters[:q].present?
      term = "%#{@filters[:q].strip}%"
      scope = scope.where(
        "full_name ILIKE :term
         OR COALESCE(cpf_cnpj, '') ILIKE :term
         OR COALESCE(phone, '') ILIKE :term
         OR COALESCE(email, '') ILIKE :term",
        term: term
      )
    end

    if @filters[:cadastro_pendente].present?
      scope = scope.where(cadastro_pendente: ActiveModel::Type::Boolean.new.cast(@filters[:cadastro_pendente]))
    end

    if @filters[:city].present?
      scope = scope.where("COALESCE(city, '') ILIKE ?", "%#{@filters[:city].strip}%")
    end

    @clients = scope
    @advanced_filters_open = false

    return unless request.format.json?

    render json: ClientsSnapshot.new(
      office: current_office,
      unit: current_unit,
      clients: @clients,
      filters: @filters
    ).as_json
  end

  def show
    @client_legal_cases = scope_by_current_unit(@client.legal_cases).order(updated_at: :desc)
  end

  def new
    @client = current_office.clients.new(unit: current_unit)
  end

  def edit
  end

  def create
    @client = current_office.clients.new(client_params)
    @client.unit ||= current_unit

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
    @client.unit ||= current_unit

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
    @client = scope_by_current_unit(current_office.clients).find(params.expect(:id))
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

  def client_filters
    params.permit(:q, :cadastro_pendente, :city)
  end
end
