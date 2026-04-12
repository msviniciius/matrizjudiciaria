class CourtsController < ApplicationController
  before_action :set_court, only: %i[show edit update destroy]

  def index
    @courts = Court.includes(:district).order(:name)
  end

  def show
  end

  def new
    @court = Court.new
  end

  def edit
  end

  def create
    @court = Court.new(court_params)

    if @court.save
      redirect_to courts_path, notice: "Órgão/Vara/Tribunal cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @court.update(court_params)
      redirect_to courts_path, notice: "Órgão/Vara/Tribunal atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @court.destroy!
    redirect_to courts_path, notice: "Órgão/Vara/Tribunal excluído com sucesso."
  end

  private

  def set_court
    @court = Court.find(params.expect(:id))
  end

  def court_params
    params.expect(court: [:name, :district_id])
  end
end
