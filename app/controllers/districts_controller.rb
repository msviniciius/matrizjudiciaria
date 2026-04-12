class DistrictsController < ApplicationController
  before_action :set_district, only: %i[show edit update destroy]

  def index
    @districts = District.order(:name)
  end

  def show
  end

  def new
    @district = District.new
  end

  def edit
  end

  def create
    @district = District.new(district_params)

    if @district.save
      redirect_to districts_path, notice: "Comarca cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @district.update(district_params)
      redirect_to districts_path, notice: "Comarca atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @district.destroy!
    redirect_to districts_path, notice: "Comarca excluída com sucesso."
  end

  private

  def set_district
    @district = District.find(params.expect(:id))
  end

  def district_params
    params.expect(district: [:name])
  end
end
