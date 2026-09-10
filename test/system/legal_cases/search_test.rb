require_relative "../legal_cases_test_case"

class LegalCasesSearchTest < LegalCasesSystemTestCase
  test "searches processes by internal number and updates the URL" do
    _office, unit, user, area, process_type = create_system_context
    matching_case = create_process_for(
      unit,
      area,
      process_type,
      client_name: "Cliente Aurora",
      internal_number: "PROC-AURORA-001"
    )
    other_case = create_process_for(
      unit,
      area,
      process_type,
      client_name: "Cliente Boreal",
      internal_number: "PROC-BOREAL-001"
    )

    sign_in_and_select(user, unit)
    visit legal_cases_path
    assert_selector "a.react-legal-cases__card", text: matching_case.internal_number
    assert_selector "a.react-legal-cases__card", text: other_case.internal_number

    fill_in "Busca", with: "AURORA"
    click_on "Buscar"

    assert_selector "a.react-legal-cases__card", text: matching_case.internal_number
    assert_no_text other_case.internal_number
    assert_current_path legal_cases_path(q: "AURORA")
    assert_text "1 processo(s)"
  end

  test "shows an empty state when the search has no matches" do
    _office, unit, user, area, process_type = create_system_context
    create_process_for(
      unit,
      area,
      process_type,
      client_name: "Cliente Existente",
      internal_number: "PROC-EXISTENTE-001"
    )

    sign_in_and_select(user, unit)
    visit legal_cases_path
    fill_in "Busca", with: "Processo inexistente"
    click_on "Buscar"

    assert_text "Nenhum processo encontrado para estes filtros."
    assert_text "0 processo(s)"
  end
end
