class OfficeUsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = current_office.users.order(:name, :email)
  end

  def new
    @user = current_office.users.new(role: "attendant", active: true)
    @user.unit_ids = [ current_unit.id ].compact
  end

  def create
    @user = current_office.users.new(user_params)

    if @user.save
      redirect_to office_setting_users_path, notice: "Usuário criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = user_params.to_h
    if attrs["password"].blank?
      attrs.delete("password")
      attrs.delete("password_confirmation")
    end

    if @user.update(attrs)
      redirect_to office_setting_users_path, notice: "Usuário atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to office_setting_users_path, alert: "Você não pode excluir seu próprio usuário."
      return
    end

    @user.destroy!
    redirect_to office_setting_users_path, notice: "Usuário removido com sucesso.", status: :see_other
  end

  private

  def set_user
    @user = current_office.users.find(params.expect(:id))
  end

  def user_params
    params.expect(user: [ :name, :email, :role, :active, :password, :password_confirmation, unit_ids: [] ])
  end
end
