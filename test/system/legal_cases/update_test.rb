require_relative "../legal_cases_test_case"

class LegalCasesUpdateTest < LegalCasesSystemTestCase
  test "updates a process through the form" do
    _office, unit, user, area, process_type = create_system_context
    legal_case = create_process_for(
      unit,
      area,
      process_type,
      client_name: "Cliente do processo",
      internal_number: "PROC-EDITAR-001",
      opposing_party: "Parte original"
    )

    sign_in_and_select(user, unit)
    visit edit_legal_case_path(legal_case)

    assert_selector "h1", text: "Editar processo"
    fill_in "legal_case_opposing_party", with: ""
    fill_in "legal_case_opposing_party", with: "Parte atualizada"
    fill_in "legal_case_last_movement", with: ""
    fill_in "legal_case_last_movement", with: "Andamento atualizado"
    find("form.app-form input[type=submit]").click

    assert_text "Processo atualizado com sucesso."
    assert_current_path legal_case_path(legal_case)
    assert_equal "Parte atualizada", legal_case.reload.opposing_party
    assert_equal "Andamento atualizado", legal_case.last_movement
  end
end
