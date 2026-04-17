class MovementTypesController < ApplicationController
  before_action :set_movement_type, only: %i[ show edit update destroy ]

  def index
    @movement_types = MovementType.order(:name)
  end

  def show
  end

  def new
    @movement_type = MovementType.new
  end

  def edit
  end

  def create
    @movement_type = MovementType.new(movement_type_params)

    if @movement_type.save
      redirect_to movement_types_path, notice: "Tipo de andamento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @movement_type.update(movement_type_params)
      redirect_to movement_types_path, notice: "Tipo de andamento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @movement_type.destroy!
    redirect_to movement_types_path, notice: "Tipo de andamento excluído com sucesso."
  end

  private

  def set_movement_type
    @movement_type = MovementType.find(params.expect(:id))
  end

  def movement_type_params
    params.expect(movement_type: [ :name, :code, :active ])
  end
end
