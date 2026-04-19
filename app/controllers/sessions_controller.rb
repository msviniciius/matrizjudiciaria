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
      redirect_to root_path, notice: "Login realizado com sucesso."
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
