require_relative "../legal_cases_test_case"

class LegalCasesIndexTest < LegalCasesSystemTestCase
  test "lists only processes from the selected unit" do
    _office, unit, user, area, process_type = create_system_context
    selected_case = create_process_for(
      unit,
      area,
      process_type,
      client_name: "Cliente do processo",
      internal_number: "PROC-UNIDADE-001"
    )
    other_unit = Unit.create!(office: unit.office, name: "Outra unidade #{SecureRandom.hex(4)}")
    other_case = create_process_for(
      other_unit,
      area,
      process_type,
      client_name: "Cliente de outra unidade",
      internal_number: "PROC-OUTRA-001"
    )

    sign_in_and_select(user, unit)
    visit legal_cases_path

    assert_selector "h1", text: "Processos"
    assert_selector "a.react-legal-cases__card", text: selected_case.internal_number
    assert_no_text other_case.internal_number
    assert_text "1 processo(s)"
    assert_link "Novo processo", href: new_legal_case_path
  end
end
