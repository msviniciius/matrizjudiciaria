require_relative "../legal_cases_test_case"

class LegalCasesCreateTest < LegalCasesSystemTestCase
  test "creates a process through the form" do
    _office, unit, user, area, process_type = create_system_context
    client = Client.create!(
      office: unit.office,
      unit: unit,
      full_name: "Cliente do novo processo",
      cpf_cnpj: "99999999999"
    )

    sign_in_and_select(user, unit)
    visit new_legal_case_path

    assert_text "Novo processo"
    select_custom_option("Cliente", client.display_name_with_status)
    select_process_type(area, process_type)
    fill_in "legal_case_opposing_party", with: "Parte contrária"
    fill_in "legal_case_last_movement", with: "Primeiro andamento"
    fill_in "legal_case_next_deadline_on", with: (Date.current + 3.days).to_s
    find("form.app-form input[type=submit]").click

    assert_text "Processo cadastrado com sucesso."
    assert_current_path %r{\A/legal_cases/\d+\z}
    created_case = LegalCase.find_by!(opposing_party: "Parte contrária")
    assert_current_path legal_case_path(created_case)
    assert_equal unit.id, created_case.unit_id
    assert_equal client.id, created_case.client_id
    assert_equal process_type.id, created_case.process_type_id
  end

  test "creates a process with an examination through the form" do
    _office, unit, user, area, process_type = create_system_context
    client = Client.create!(
      office: unit.office,
      unit: unit,
      full_name: "Cliente com perícia",
      cpf_cnpj: "88888888888"
    )

    sign_in_and_select(user, unit)
    visit new_legal_case_path

    select_custom_option("Cliente", client.display_name_with_status)
    select_process_type(area, process_type)
    check "Tem perícia?"
    assert_selector "dialog[data-pericia-modal][open]", wait: 5

    within("dialog[data-pericia-modal]") do
      select_custom_option("Natureza", "Médica")
      select_custom_option("Esfera", "Judicial")
      select_custom_option("Status", "Designada")
      fill_in "Data/hora", with: "2026-09-15T14:00"
      fill_in "Local", with: "Fórum Central"
      fill_in "Perito", with: "Dra. Ana Perita"
      fill_in "Observações", with: "Levar documentos médicos."
      click_on "Salvar"
    end

    assert_text "Processo cadastrado com sucesso."
    created_case = LegalCase.find_by!(client: client)
    exam = created_case.reload.process_exams.first
    assert_not_nil exam
    assert_equal "medica", exam.exam_nature
    assert_equal "judicial", exam.exam_scope
    assert_equal "designada", exam.status
    assert_equal "Dra. Ana Perita", exam.expert_name
    assert_equal "Fórum Central", exam.location
  end

  test "shows validation errors when the client is missing" do
    _office, _unit, user, area, process_type = create_system_context

    sign_in_and_select(user, _unit)
    visit new_legal_case_path
    select_process_type(area, process_type)
    page.execute_script("document.querySelector('form.app-form').noValidate = true")
    find("form.app-form input[type=submit]").click

    assert_current_path legal_cases_path
    assert_text "Foram encontrados"
    assert_text "Client deve existir"
  end
end
