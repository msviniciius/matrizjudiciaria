class UnitSessionsController < ApplicationController
  def new
    @units = current_user.available_units.ordered
    redirect_to root_path if @units.empty?
  end

  def create
    if params[:all_units] == "1" || (params[:unit_id].blank? && current_user.admin?)
      if current_user.admin?
        session[:all_units] = true
        session.delete(:current_unit_id)
        redirect_to root_path, notice: "Visão consolidada habilitada."
      else
        redirect_to root_path, alert: "Apenas administradores podem acessar visão consolidada."
      end
      return
    end

    unit = current_user.available_units.find(params.expect(:unit_id))
    session[:current_unit_id] = unit.id
    session[:all_units] = false
    redirect_to root_path, notice: "Unidade selecionada: #{unit.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Unidade inválida para este usuário."
  end
end
