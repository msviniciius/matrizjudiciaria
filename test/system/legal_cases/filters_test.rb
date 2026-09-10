require_relative "../legal_cases_test_case"
require "uri"

class LegalCasesFiltersTest < LegalCasesSystemTestCase
  test "filters processes by status and priority" do
    _office, unit, user, area, process_type = create_system_context
    matching_case = create_process_for(
      unit,
      area,
      process_type,
      client_name: "Processo urgente",
      internal_number: "PROC-FILTRO-001",
      status: "aguardando_cliente",
      priority: "urgent"
    )
    create_process_for(
      unit,
      area,
      process_type,
      client_name: "Processo em análise",
      internal_number: "PROC-FILTRO-002",
      status: "em_analise",
      priority: "urgent"
    )
    create_process_for(
      unit,
      area,
      process_type,
      client_name: "Processo aguardando cliente médio",
      internal_number: "PROC-FILTRO-003",
      status: "aguardando_cliente",
      priority: "medium"
    )

    sign_in_and_select(user, unit)
    visit legal_cases_path
    click_on "Filtros avançados"
    select "Aguardando cliente", from: "Status"
    select "Urgente", from: "Prioridade"

    assert_selector "a.react-legal-cases__card", text: matching_case.internal_number
    assert_no_text "PROC-FILTRO-002"
    assert_no_text "PROC-FILTRO-003"
    assert_equal(
      { "status" => "aguardando_cliente", "priority" => "urgent" },
      Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)
    )
    assert_text "1 processo(s)"
  end
end
