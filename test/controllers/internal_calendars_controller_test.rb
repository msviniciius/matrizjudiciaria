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
    assert_select "#react-internal-calendar-root"
    assert_select "script[src*='internal_calendar']"
  end

  test "should get internal calendar list view" do
    get internal_calendar_url(format: :json), params: { month: Date.current.strftime("%Y-%m"), view: "list" }

    assert_response :success
    body = response.parsed_body
    assert_equal "list", body.dig("meta", "view_mode")
    assert_equal Date.current.strftime("%Y-%m"), body.dig("meta", "reference_month")
    assert_equal internal_calendar_path(month: Date.current.strftime("%Y-%m"), view: "month"), body.dig("actions", "month")
    assert_includes body.fetch("events").map { |event| event.fetch("title") }, "Tarefa de teste"
    assert_includes body.fetch("events").map { |event| event.fetch("type_label") }, "Perícia"
  end

  test "calendar deadline event exposes legal metadata and respects the active unit" do
    unit = Unit.create!(office: @office, name: "Contencioso calendário")
    other_unit = Unit.create!(office: @office, name: "Consultivo calendário")
    @legal_case.update!(unit: unit)
    other_case = LegalCase.create!(@legal_case.attributes.slice(*LegalCase.column_names).except("id", "created_at", "updated_at").merge(internal_number: "PROC-CAL-OTHER", unit_id: other_unit.id))
    other_deadline = Deadline.create!(legal_case: other_case, title: "Fora da unidade", due_date: Date.current + 1.day, status: :pending)
    expediente = @legal_case.expedientes.create!(tipo: :intimacao, descricao: "Expediente calendário", data_disponibilizacao: Date.current, quantidade_dias: 2, contagem: :uteis, prazo_em_dobro: false, origem: :pje)
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.current)
    expediente.deadline.update!(start_date: Date.current + 1.day, due_date: Date.current + 1.day, status: :in_progress)
    sign_in_and_select(unit)

    get internal_calendar_url(format: :json), params: { month: Date.current.strftime("%Y-%m"), view: "list" }

    assert_response :success
    events = response.parsed_body.fetch("events")
    legal_event = events.find { |event| event.fetch("url") == deadline_path(expediente.deadline) }
    assert_equal "pje", legal_event.fetch("origin")
    assert_equal "in_progress", legal_event.fetch("legal_state")
    assert_equal expediente.id, legal_event.dig("expediente", "id")
    assert_not_includes events.map { |event| event.fetch("url") }, deadline_path(other_deadline)
  end

  private

  def sign_in_and_select(unit)
    admin = User.create!(office: @office, name: "Admin calendário", email: "admin-cal-#{SecureRandom.hex(4)}@example.com", role: "admin", password: "segredo123", password_confirmation: "segredo123")
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end
end
