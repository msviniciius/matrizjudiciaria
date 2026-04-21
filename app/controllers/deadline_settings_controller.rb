class DeadlineSettingsController < ApplicationController
  before_action :set_deadline_setting, only: %i[edit update destroy]

  def index
    @deadline_settings = current_office.deadline_settings.ordered
  end

  def new
    @deadline_setting = current_office.deadline_settings.new(active: true)
  end

  def edit
  end

  def create
    @deadline_setting = current_office.deadline_settings.new(deadline_setting_params)

    if @deadline_setting.save
      redirect_to deadline_settings_path, notice: "Regra de prazo cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @deadline_setting.update(deadline_setting_params)
      redirect_to deadline_settings_path, notice: "Regra de prazo atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deadline_setting.destroy!
    redirect_to deadline_settings_path, notice: "Regra de prazo excluída com sucesso.", status: :see_other
  end

  private

  def set_deadline_setting
    @deadline_setting = current_office.deadline_settings.find(params.expect(:id))
  end

  def deadline_setting_params
    params.expect(deadline_setting: [ :name, :deadline_type, :days_to_due, :default_priority, :justification_hint, :active ])
  end
end
