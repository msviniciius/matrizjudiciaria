MissionControl::Jobs.base_controller_class = "JobsDashboardController"
MissionControl::Jobs.http_basic_auth_enabled = false

module MissionControlJobsI18nIsolation
  private

  def set_current_locale(&block)
    I18n.with_locale(:en, &block)
  end
end

Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.prepend(MissionControlJobsI18nIsolation)
end
