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
    attributes = office_params
    remove_logo = logo_removal_requested? && attributes[:logo].blank?

    if @office.update(attributes)
      @office.logo.purge if remove_logo && @office.logo_attached?
      redirect_to edit_office_setting_path, notice: "Configurações do escritório atualizadas com sucesso."
    else
      discard_pending_logo_change
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
      :oab_state,
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

  def logo_removal_requested?
    return unless params[:office].is_a?(ActionController::Parameters)

    params[:office][:remove_logo] == "1"
  end

  def discard_pending_logo_change
    @office.attachment_changes.delete("logo")
  end
end
