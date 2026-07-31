class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]

  layout "authentication"

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    users = User.active.includes(:office).where(email: params[:email].to_s.downcase.strip)
    user = users.one? ? users.first : nil

    if user&.authenticate(params[:password].to_s)
      session[:user_id] = user.id
      user.record_sign_in!
      units = user.available_units

      if user.admin?
        session.delete(:current_unit_id)
        session.delete(:current_context)
        session[:all_units] = false
        redirect_to root_path, notice: "Selecione a unidade para continuar."
      elsif user.matrix_access? && units.empty?
        session.delete(:current_unit_id)
        session[:current_context] = "matrix"
        session[:all_units] = false
        redirect_to root_path, notice: "Login realizado com sucesso."
      elsif units.count == 1 && !user.matrix_access?
        session[:current_unit_id] = units.first&.id
        session[:current_context] = "unit"
        session[:all_units] = false
        redirect_to root_path, notice: "Login realizado com sucesso."
      else
        session.delete(:current_unit_id)
        session.delete(:current_context)
        session[:all_units] = false
        redirect_to root_path, notice: "Selecione a unidade para continuar."
      end
    else
      flash.now[:alert] =
        if users.many?
          "Existe mais de um usuário ativo com este e-mail. Fale com o administrador."
        else
          "E-mail ou senha inválidos."
        end
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sessão encerrada."
  end
end
