class OfficeSettingsController < ApplicationController
  before_action :require_admin!

  def show
    redirect_to edit_office_setting_path
  end

  def edit
    @office = current_office
    @users = current_office.users.order(:name, :email)
  end

  def update
    @office = current_office
    @users = current_office.users.order(:name, :email)

    purge_logo_if_requested

    if @office.update(office_params)
      redirect_to edit_office_setting_path, notice: "Configurações do escritório atualizadas com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def office_params
    params.expect(office: [
      :name,
      :legal_name,
      :cnpj,
      :oab_registration,
      :email,
      :phone,
      :zip_code,
      :address,
      :city,
      :state,
      :logo,
      :primary_color,
      :secondary_color,
      { enabled_tribunals: [] },
      :default_phase,
      :default_status,
      :default_priority,
      :deadline_alert_days,
      :task_alert_days
    ])
  end

  def purge_logo_if_requested
    return unless params[:office].is_a?(ActionController::Parameters)
    return unless params[:office][:remove_logo] == "1"
    return unless current_office.logo_attached?

    current_office.logo.purge
  end
end
