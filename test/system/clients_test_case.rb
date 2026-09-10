require_relative "../application_system_test_case"

class ClientsSystemTestCase < ApplicationSystemTestCase
  private

  def create_system_context
    token = SecureRandom.hex(4)
    office = Office.create!(name: "System Clients #{token}", slug: "system-clients-#{token}")
    @system_office = office
    unit = Unit.create!(office: office, name: "Clientes #{SecureRandom.hex(4)}")
    user = User.create!(
      office: office,
      name: "Administrador de clientes",
      email: "clientes-#{SecureRandom.hex(4)}@example.com",
      role: "attendant",
      matrix_access: false,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    UserUnit.create!(user: user, unit: unit)

    [ office, unit, user ]
  end

  def teardown
    Capybara.reset_sessions!
    @system_office&.destroy!
    super
  end

  def sign_in_and_select(user, unit)
    visit login_path
    fill_in "E-mail", with: user.email
    fill_in "login_password", with: "segredo123"
    click_on "Entrar"
    assert_current_path root_path
  end

  def create_client_for(unit, full_name:, cpf_cnpj:, **attributes)
    Client.create!(
      {
        office: unit.office,
        unit: unit,
        full_name: full_name,
        cpf_cnpj: cpf_cnpj
      }.merge(attributes)
    )
  end
end
