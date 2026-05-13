class UnitsController < ApplicationController
  before_action :require_admin!
  before_action :set_unit, only: %i[show edit update destroy]

  def index
    @units = current_office.units.ordered
  end

  def show
  end

  def new
    @unit = current_office.units.new(active: true)
  end

  def edit
  end

  def create
    @unit = current_office.units.new(unit_params)

    if @unit.save
      redirect_to units_path, notice: "Unidade cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @unit.update(unit_params)
      redirect_to units_path, notice: "Unidade atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy!
    redirect_to units_path, notice: "Unidade excluída com sucesso.", status: :see_other
  end

  private

  def set_unit
    @unit = current_office.units.find(params.expect(:id))
  end

  def unit_params
    params.expect(unit: [ :name, :slug, :active ])
  end
end
