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

  test "uploads and persists office logo after reload" do
    patch office_setting_path, params: { office: { logo: logo_upload(filename: "first-logo.png") } }

    assert_redirected_to edit_office_setting_path
    assert_predicate default_office.reload.logo, :attached?
    assert_equal "first-logo.png", default_office.logo.filename.to_s

    get edit_office_setting_path

    assert_response :success
    assert_select ".office-logo-preview img", count: 1
  end

  test "replaces existing office logo" do
    patch office_setting_path, params: { office: { logo: logo_upload(filename: "first-logo.png") } }
    original_blob_id = default_office.reload.logo.blob.id

    patch office_setting_path, params: { office: { logo: logo_upload(filename: "replacement-logo.png") } }

    assert_redirected_to edit_office_setting_path
    assert_not_equal original_blob_id, default_office.reload.logo.blob.id
    assert_equal "replacement-logo.png", default_office.logo.filename.to_s
  end

  test "removes existing office logo after a valid update" do
    default_office.logo.attach(logo_upload(filename: "logo-to-remove.png"))

    patch office_setting_path, params: {
      office: { name: default_office.name, remove_logo: "1" }
    }

    assert_redirected_to edit_office_setting_path
    assert_not_predicate default_office.reload.logo, :attached?
  end

  test "preserves existing logo when removal is requested with an invalid update" do
    default_office.logo.attach(logo_upload(filename: "preserved-logo.png"))
    original_blob_id = default_office.logo.blob.id

    patch office_setting_path, params: {
      office: { remove_logo: "1", deadline_alert_days: -1 }
    }

    assert_response :unprocessable_entity
    assert_equal original_blob_id, default_office.reload.logo.blob.id
  end

  test "new upload takes precedence over removal request" do
    default_office.logo.attach(logo_upload(filename: "original-logo.png"))
    original_blob_id = default_office.logo.blob.id

    patch office_setting_path, params: {
      office: {
        remove_logo: "1",
        logo: logo_upload(filename: "replacement-wins.png")
      }
    }

    assert_redirected_to edit_office_setting_path
    assert_predicate default_office.reload.logo, :attached?
    assert_not_equal original_blob_id, default_office.logo.blob.id
    assert_equal "replacement-wins.png", default_office.logo.filename.to_s
  end

  test "rejects unsupported logo and preserves persisted attachment" do
    default_office.logo.attach(logo_upload(filename: "valid-logo.png"))
    original_blob_id = default_office.logo.blob.id

    patch office_setting_path, params: {
      office: { logo: uploaded_file("not an image", content_type: "text/plain", filename: "invalid.txt") }
    }

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /deve ser PNG, JPEG ou WebP/
    assert_equal original_blob_id, default_office.reload.logo.blob.id
  end

  test "rejects oversized logo and preserves persisted attachment" do
    default_office.logo.attach(logo_upload(filename: "valid-logo.png"))
    original_blob_id = default_office.logo.blob.id

    patch office_setting_path, params: {
      office: { logo: logo_upload(filename: "oversized-logo.png", padding: Office::LOGO_MAX_SIZE) }
    }

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /deve ter no máximo 5 MB/
    assert_equal original_blob_id, default_office.reload.logo.blob.id
  end

  test "does not allow a non administrator to replace the logo" do
    default_office.logo.attach(logo_upload(filename: "admin-logo.png"))
    original_blob_id = default_office.logo.blob.id
    attendant = User.create!(
      office: default_office,
      name: "Atendente Configuracoes",
      email: "atendente-configuracoes-#{SecureRandom.hex(4)}@example.com",
      role: "attendant",
      password: "segredo123",
      password_confirmation: "segredo123",
      active: true,
      matrix_access: true
    )
    delete logout_path
    post login_path, params: { email: attendant.email, password: "segredo123" }

    patch office_setting_path, params: { office: { logo: logo_upload(filename: "forbidden-logo.png") } }

    assert_redirected_to root_path
    assert_equal "Apenas administradores podem acessar esta área.", flash[:alert]
    assert_equal original_blob_id, default_office.reload.logo.blob.id
  end

  test "updates only current office when another office id is submitted" do
    other_office = Office.create!(name: "Outro Escritorio", slug: "outro-escritorio")
    other_office.logo.attach(logo_upload(filename: "other-logo.png"))
    other_blob_id = other_office.logo.blob.id

    patch office_setting_path, params: {
      office: {
        office_id: other_office.id,
        logo: logo_upload(filename: "current-office-logo.png")
      }
    }

    assert_redirected_to edit_office_setting_path
    assert_equal "current-office-logo.png", default_office.reload.logo.filename.to_s
    assert_equal other_blob_id, other_office.reload.logo.blob.id
  end
end
