require "test_helper"

class InternalCalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @office = Office.create!(name: "Escritorio Teste")
    @client = Client.create!(office: @office, full_name: "Cliente Teste", cpf_cnpj: "11122233344")
    @district = District.create!(name: "Sao Luis/MA")
    @court = Court.create!(name: "1a Vara Civel", district: @district)
    @legal_area = LegalArea.create!(name: "Previdenciario", justice_branch: "federal")
    @process_type = ProcessType.create!(name: "Concessao", legal_area: @legal_area)

    @legal_case = LegalCase.create!(
      office: @office,
      client: @client,
      internal_number: "PROC-CAL-001",
      external_number: "0000001-00.2026.8.10.0001",
      entry_date: Date.current,
      protocol_date: Date.current,
      subarea: "Subarea",
      main_subject: "Assunto",
      phase: "analise_juridica",
      status: "em_analise",
      responsible_name: "Responsavel",
      next_action: "Proxima acao",
      next_deadline_on: Date.current + 2.days,
      claim_value: 1000,
      priority: "medium",
      legal_area_id: @legal_area.id,
      process_type_id: @process_type.id,
      district_id: @district.id,
      court_id: @court.id
    )

    Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo de teste",
      due_date: Date.current + 1.day,
      status: "pending",
      priority: "medium"
    )

    Task.create!(
      legal_case: @legal_case,
      title: "Tarefa de teste",
      due_date: Date.current + 1.day,
      status: "pending",
      priority: "medium"
    )

    ProcessExam.create!(
      legal_case: @legal_case,
      exam_nature: "medica",
      exam_scope: "judicial",
      status: "designada",
      scheduled_at: Time.zone.now.beginning_of_day + 1.day + 9.hours,
      active: true
    )
  end

  test "should get internal calendar month view" do
    get internal_calendar_url

    assert_response :success
    assert_includes @response.body, "Calendário interno"
    assert_includes @response.body, "Prazo de teste"
  end

  test "should get internal calendar list view" do
    get internal_calendar_url(month: Date.current.strftime("%Y-%m"), view: "list")

    assert_response :success
    assert_includes @response.body, "Tarefa de teste"
    assert_includes @response.body, "Perícia"
  end
end
