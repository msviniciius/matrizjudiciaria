class MovementTypesController < ApplicationController
  before_action :set_movement_type, only: %i[ show edit update destroy ]

  def index
     = MovementType.order(:name)
  end

  def show
  end

  def new
     = MovementType.new
  end

  def edit
  end

  def create
     = MovementType.new(movement_type_params)

    if .save
      redirect_to movement_types_path, notice: "Tipo de andamento cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if .update(movement_type_params)
      redirect_to movement_types_path, notice: "Tipo de andamento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    .destroy!
    redirect_to movement_types_path, notice: "Tipo de andamento excluído com sucesso."
  end

  private

  def set_movement_type
     = MovementType.find(params.expect(:id))
  end

  def movement_type_params
    params.expect(movement_type: [ :name, :code, :active ])
  end
end
