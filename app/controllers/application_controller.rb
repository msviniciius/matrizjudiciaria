class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_context
  before_action :authenticate_user!
  before_action :ensure_unit_context!
  before_action :load_navbar_notifications

  helper_method :current_user, :current_office, :current_unit, :all_units_mode?, :user_signed_in?

  private

  def current_user
    @current_user ||= User.active.includes(:office).find_by(id: session[:user_id])
  end

  def current_office
    @current_office ||= current_user&.office || Office.order(:id).first
  end

  def user_signed_in?
    current_user.present?
  end

  def current_unit
    return nil if current_user.blank?
    return nil if all_units_mode?

    @current_unit ||= current_user.available_units.find_by(id: session[:current_unit_id])
  end

  def all_units_mode?
    current_user&.admin? && session[:all_units] == true
  end

  def authenticate_user!
    return true if Rails.env.test?
    return if user_signed_in?

    redirect_to login_path, alert: "Faça login para acessar o sistema."
  end

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "Apenas administradores podem acessar esta área."
  end

  def set_current_context
    Current.user = current_user
    Current.office = current_office
    Current.unit = current_unit
  end

  def ensure_unit_context!
    return unless user_signed_in?

    units = current_user.available_units
    return if units.empty?
    return if all_units_mode?
    return if current_unit.present?
    return if current_user.admin?

    if units.count == 1
      session[:current_unit_id] = units.first.id
      session[:all_units] = false
    end
  end

  def scope_by_current_unit(scope)
    # Em teste (sem usuario logado), retorna escopo sem filtro
    return scope if current_user.blank?
    return scope if all_units_mode?
    return scope unless scope.klass.column_names.include?("unit_id")
    return scope.none if current_unit.blank?

    scope.where(unit_id: current_unit.id)
  end

  def load_navbar_notifications
    return unless user_signed_in?
    return if current_office.blank?

    deadline_limit = Date.current + current_office.deadline_alert_days.days
    task_limit = Date.current + current_office.task_alert_days.days

    @navbar_deadlines = Deadline
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .where(status: %w[pending in_progress overdue extended])
      .where.not(due_date: nil)
      .where(due_date: ..deadline_limit)
      .order(:due_date)
      .limit(5)

    @navbar_tasks = Task
      .joins(:legal_case)
      .where(legal_cases: { office_id: current_office.id })
      .where(status: %w[pending in_progress])
      .where.not(due_date: nil)
      .where(due_date: ..task_limit)
      .order(:due_date)
      .limit(5)

    unless all_units_mode?
      @navbar_deadlines = @navbar_deadlines.where(legal_cases: { unit_id: current_unit&.id })
      @navbar_tasks = @navbar_tasks.where(legal_cases: { unit_id: current_unit&.id })
    end

    @navbar_notification_total = @navbar_deadlines.size + @navbar_tasks.size
  end
end
