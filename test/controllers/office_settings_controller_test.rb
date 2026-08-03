require "test_helper"

class OfficeSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      office: default_office,
      name: "Admin Configuracoes",
      email: "admin-configuracoes-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123",
      active: true,
      matrix_access: true
    )

    post login_path, params: { email: @admin.email, password: "segredo123" }
  end

  test "edit renders oab state field" do
    get edit_office_setting_path

    assert_response :success
    assert_select "input[name='office[oab_state]']"
  end

  test "updates and normalizes office oab settings" do
    patch office_setting_path, params: {
      office: {
        name: default_office.name,
        legal_name: default_office.legal_name,
        cnpj: default_office.cnpj,
        oab_registration: "OAB 18.727",
        oab_state: "ma",
        email: default_office.email,
        phone: default_office.phone,
        zip_code: default_office.zip_code,
        address: default_office.address,
        city: default_office.city,
        state: default_office.state,
        primary_color: default_office.primary_color,
        secondary_color: default_office.secondary_color,
        enabled_tribunals: default_office.enabled_tribunal_codes,
        default_phase: default_office.default_phase,
        default_status: default_office.default_status,
        default_priority: default_office.default_priority,
        deadline_alert_days: default_office.deadline_alert_days,
        task_alert_days: default_office.task_alert_days
      }
    }

    assert_redirected_to edit_office_setting_path
    assert_equal "18727", default_office.reload.oab_registration
    assert_equal "MA", default_office.oab_state
  end
end
