class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_context
  before_action :authenticate_user!
  before_action :load_navbar_notifications

  helper_method :current_user, :current_office, :user_signed_in?

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

    @navbar_notification_total = @navbar_deadlines.size + @navbar_tasks.size
  end
end
