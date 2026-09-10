require_relative "../application_system_test_case"

class LegalCasesSystemTestCase < ApplicationSystemTestCase
  private

  def create_system_context
    token = SecureRandom.hex(4)
    office = Office.create!(name: "System Processes #{token}", slug: "system-processes-#{token}")
    unit = Unit.create!(office: office, name: "Processos #{SecureRandom.hex(4)}")
    user = User.create!(
      office: office,
      name: "Administrador de processos",
      email: "processos-#{SecureRandom.hex(4)}@example.com",
      role: "attendant",
      matrix_access: false,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    UserUnit.create!(user: user, unit: unit)

    area = LegalArea.create!(name: "Cível #{SecureRandom.hex(3)}", justice_branch: "estadual")
    process_type = ProcessType.create!(name: "Procedimento #{SecureRandom.hex(3)}", legal_area: area)

    @system_office = office
    [ office, unit, user, area, process_type ]
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

    visit new_unit_session_path
    select unit.name, from: "Unidade"
    click_on "Entrar na unidade"
    assert_current_path root_path
  end

  def create_process_for(unit, area, process_type, client_name:, internal_number:, **attributes)
    client = Client.create!(
      office: unit.office,
      unit: unit,
      full_name: client_name,
      cpf_cnpj: SecureRandom.random_number(10**10).to_s.rjust(11, "0")
    )

    LegalCase.create!(
      {
        office: unit.office,
        unit: unit,
        client: client,
        legal_area: area,
        process_type: process_type,
        internal_number: internal_number,
        phase: "analise_juridica",
        status: "em_analise",
        priority: "medium",
        responsible_name: "Responsável do processo",
        next_action: "Acompanhar processo",
        next_deadline_on: Date.current + 5.days
      }.merge(attributes)
    )
  end

  def select_process_type(area, process_type)
    select_custom_option("Área do direito", area.name)
    assert_selector ".custom-select__item", text: process_type.name, visible: :all, wait: 5
    select_custom_option("Tipo de processo", process_type.name)
  end

  def select_custom_option(label_text, option_text)
    label = find("label", text: /\A#{Regexp.escape(label_text)}\z/)
    field = label.find(:xpath, "..")
    field.find(".custom-select__trigger").click
    field.find(".custom-select__item", text: option_text).click
  end
end
