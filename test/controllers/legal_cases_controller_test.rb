require "test_helper"
require "rack/utils"
require "uri"

class LegalCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies(
      legal_area_name: "Civel",
      process_type_name: "Procedimento Comum"
    )

    @client = create_client(full_name: "Cliente Base", cpf_cnpj: "11111111111")

    @legal_case = create_full_legal_case(
      internal_number: "PROC-BASE-001",
      client: @client,
      external_number: "0000001-00.2026.8.10.0001",
      entry_date: Date.current,
      protocol_date: Date.current,
      subarea: "Subarea",
      main_subject: "Assunto",
      claim_value: 1000,
      priority: "medium"
    )

    Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo inicial",
      due_date: Date.current + 3.days,
      status: "pending",
      priority: "medium"
    )
  end

  test "should get index" do
    get legal_cases_url
    assert_response :success
  end

  test "index mounts the React legal cases application" do
    get legal_cases_url

    assert_response :success
    assert_select "#react-legal-cases-root"
    assert_select "script[src*='legal_cases']"
    assert_select "script[src*='legal_case_show']", count: 0
  end

  test "show mounts the React command center" do
    get legal_case_url(@legal_case)

    assert_response :success
    assert_select "#react-legal-case-show-root"
    assert_select "script[src*='legal_case_show']"
  end

  test "show remains read only and preserves the new imported event alert" do
    imported_event = CaseEvent.create!(
      legal_case: @legal_case,
      description: "Andamento ainda não visualizado",
      entry_kind: "andamento",
      event_date: Time.current,
      pje_external_id: "show-read-only-#{SecureRandom.hex(4)}"
    )
    @legal_case.update_column(:last_viewed_events_at, imported_event.created_at - 1.minute)
    viewed_at = @legal_case.reload.last_viewed_events_at

    assert_no_changes -> { @legal_case.reload.last_viewed_events_at } do
      get legal_case_url(@legal_case)
    end

    assert_response :success
    get legal_case_url(@legal_case, format: :json)
    assert response.parsed_body.dig("alerts", "has_new_imported_events")
    assert_equal viewed_at, @legal_case.reload.last_viewed_events_at
  end

  test "does not load legal case React entrypoints outside index and show" do
    get new_legal_case_url

    assert_response :success
    assert_select "script[src*='legal_cases']", count: 0
    assert_select "script[src*='legal_case_show']", count: 0
    assert_select "script[src*='@vite/client']", count: 0
  end

  test "new preselects a permitted client from the client detail shortcut" do
    get new_legal_case_url(client_id: @client.id)

    assert_response :success
    assert_select "select[name='legal_case[client_id]'] option[selected][value='#{@client.id}']"
  end

  test "Vite manifest exposes the legal cases entrypoint" do
    entrypoint_path = ViteRuby.instance.manifest.path_for("legal_cases.tsx")

    assert_match %r{/vite-test/assets/legal_cases-.*\.js\z}, entrypoint_path
  end

  test "returns an empty legal cases snapshot as JSON without an active unit" do
    get legal_cases_url(format: :json), params: { status: "em_analise" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_empty JSON.parse(response.body).fetch("legal_cases")
  end

  test "should get new" do
    get new_legal_case_url
    assert_response :success
  end

  test "should create legal_case" do
    assert_difference("LegalCase.count") do
      post legal_cases_url, params: { legal_case: {
        internal_number: "PROC-NEW-002",
        external_number: "0000002-00.2026.8.10.0001",
        entry_date: Date.current,
        protocol_date: Date.current,
        subarea: "Subarea",
        main_subject: "Assunto",
        phase: "analise_juridica",
        status: "em_analise",
        responsible_name: "Advogado",
        next_action: "Acompanhar distribuição",
        next_deadline_on: Date.current + 2.days,
        claim_value: 2000,
        priority: "medium",
        client_id: @client.id,
        legal_area_id: @test_legal_area.id,
        process_type_id: @test_process_type.id,
        district_id: @test_district.id,
        court_id: @test_court.id
      } }
    end

    assert_redirected_to legal_case_url(LegalCase.last)
  end

  test "should show legal_case" do
    get legal_case_url(@legal_case)
    assert_response :success
  end

  test "returns the legal case detail snapshot as JSON" do
    get legal_case_url(@legal_case, format: :json)

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal @legal_case.id, response.parsed_body.dig("case", "id")
    assert_equal @legal_case.internal_number, response.parsed_body.dig("case", "internal_number")
  end

  test "show JSON does not expose a case outside the current unit" do
    unit = Unit.create!(office: default_office, name: "Contencioso detalhe")
    other_unit = Unit.create!(office: default_office, name: "Consultivo detalhe")
    other_unit_case = create_full_legal_case(unit: other_unit)
    user = User.create!(
      office: default_office,
      name: "Admin detalhe",
      email: "admin-detalhe-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )

    post login_path, params: { email: user.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
    get legal_case_url(other_unit_case, format: :json)

    assert_response :not_found
  end

  test "should get daily closure" do
    get daily_closure_legal_cases_url
    assert_response :success
  end

  test "should redirect to google calendar integration url" do
    get google_calendar_legal_case_url(@legal_case)

    assert_response :redirect
    uri = URI.parse(@response.location)
    assert_equal "calendar.google.com", uri.host
    assert_equal "/calendar/r", uri.path

    query = Rack::Utils.parse_query(uri.query)
    feed_url = URI.decode_www_form_component(query.fetch("cid"))
    assert_includes feed_url, "webcal://"
    assert_includes feed_url, "/calendar_feeds/legal_case/"
    assert_includes feed_url, ".ics"
  end

  test "syncs a legal case scoped by the callback" do
    @legal_case.update!(external_number: "")
    post sync_legal_case_url(@legal_case)

    assert_redirected_to legal_case_url(@legal_case)
    assert_equal "Este processo não possui número externo (CNJ) configurado.", flash[:alert]
  end

  test "sync returns JSON for the React detail screen" do
    post sync_legal_case_url(@legal_case),
      headers: { "ACCEPT" => "application/json" },
      env: { "legal_cases.sync_importer" => ->(**) { { imported: 1, skipped: 0 } } }

    assert_response :success
    assert_equal "1 andamento(s) novo(s) importado(s) do CNJ. 0 já existiam.", response.parsed_body.fetch("message")
    assert_equal "notice", response.parsed_body.fetch("level")
  end

  test "sync returns an alert level when no new movement is found" do
    post sync_legal_case_url(@legal_case),
      headers: { "ACCEPT" => "application/json" },
      env: { "legal_cases.sync_importer" => ->(**) { { imported: 0, skipped: 0 } } }

    assert_response :success
    assert_equal "Nenhum andamento encontrado para este processo no CNJ.", response.parsed_body.fetch("message")
    assert_equal "alert", response.parsed_body.fetch("level")
  end

  test "sync returns JSON validation feedback without an external number" do
    @legal_case.update!(external_number: "")

    post sync_legal_case_url(@legal_case), headers: { "ACCEPT" => "application/json" }

    assert_response :unprocessable_entity
    assert_equal "Este processo não possui número externo (CNJ) configurado.", response.parsed_body.fetch("error")
  end

  test "sync requires the JSON Accept header before returning JSON validation feedback" do
    @legal_case.update!(external_number: "")

    post sync_legal_case_url(@legal_case, format: :json)

    assert_redirected_to legal_case_url(@legal_case)
    assert_equal "Este processo não possui número externo (CNJ) configurado.", flash[:alert]
  end

  test "sync returns JSON server feedback when import raises" do
    post sync_legal_case_url(@legal_case),
      headers: { "ACCEPT" => "application/json" },
      env: { "legal_cases.sync_importer" => ->(**) { raise StandardError, "CNJ indisponível" } }

    assert_response :internal_server_error
    assert_equal "Erro ao sincronizar: CNJ indisponível", response.parsed_body.fetch("error")
  end

  test "should serve calendar feed in ics format with signed token" do
    get legal_case_calendar_feed_url(token: @legal_case.calendar_feed_token)

    assert_response :success
    assert_equal "text/calendar", @response.media_type
    assert_includes @response.body, "BEGIN:VCALENDAR"
    assert_includes @response.body, @legal_case.internal_number
  end

  test "should return not found with invalid calendar feed token" do
    get legal_case_calendar_feed_url(token: "token-invalido")

    assert_response :not_found
  end

  test "should get edit" do
    get edit_legal_case_url(@legal_case)
    assert_response :success
  end

  test "should update legal_case" do
    patch legal_case_url(@legal_case), params: { legal_case: {
      subarea: "Atualizada",
      legal_area_id: @test_legal_area.id,
      process_type_id: @test_process_type.id,
      district_id: @test_district.id,
      court_id: @test_court.id,
      client_id: @client.id,
      phase: @legal_case.phase,
      status: @legal_case.status
    } }

    assert_redirected_to legal_case_url(@legal_case)
  end

  test "should update legal_case with blank next_action and show warning" do
    patch legal_case_url(@legal_case), params: { legal_case: { next_action: "" } }

    assert_redirected_to legal_case_url(@legal_case)
    follow_redirect!
    assert_response :success
    assert_includes @response.body, I18n.t("legal_cases.warnings.next_action_blank")
    assert_equal "", @legal_case.reload.next_action
  end

  test "allows an administrator to record a win and activate awaiting receivables" do
    administrator = create_user(role: "admin")
    receivable = Receivable.create!(
      office: default_office,
      legal_case: @legal_case,
      description: "Honorários de êxito",
      amount: 1_500,
      trigger: "case_won",
      status: "awaiting_trigger"
    )

    sign_in(administrator)
    patch record_outcome_legal_case_url(@legal_case), params: { legal_case: {
      outcome: "won",
      outcome_date: "2026-07-30",
      outcome_notes: "Sentença favorável transitada em julgado."
    } }

    assert_redirected_to legal_case_url(@legal_case)
    assert_equal "won", @legal_case.reload.outcome
    assert_equal administrator, @legal_case.outcome_confirmed_by
    assert_not_nil @legal_case.outcome_confirmed_at
    assert_equal Date.new(2026, 7, 30), @legal_case.outcome_date
    assert_equal "Sentença favorável transitada em julgado.", @legal_case.outcome_notes
    assert_equal "pending", receivable.reload.status
    assert_not_nil receivable.triggered_at
    assert_equal 0, receivable.amount_paid
  end

  test "does not allow a non-administrator to record a case outcome" do
    unit = Unit.create!(office: default_office, name: "Contencioso")
    attendant = create_user(role: "attendant")
    UserUnit.create!(user: attendant, unit: unit)
    @legal_case.update!(unit: unit)

    sign_in(attendant)
    patch record_outcome_legal_case_url(@legal_case, format: :json), params: { legal_case: {
      outcome: "won",
      outcome_date: "2026-07-30"
    } }

    assert_redirected_to root_url
    assert_equal "undefined", @legal_case.reload.outcome
  end

  test "rejects an invalid outcome without changing the case" do
    administrator = create_user(role: "admin")

    sign_in(administrator)
    patch record_outcome_legal_case_url(@legal_case, format: :json), params: { legal_case: {
      outcome: "inconclusive",
      outcome_date: "2026-07-30"
    } }

    assert_response :unprocessable_entity
    assert_equal "undefined", @legal_case.reload.outcome
  end

  test "rejects a malformed outcome date without changing the case" do
    administrator = create_user(role: "admin")

    sign_in(administrator)
    patch record_outcome_legal_case_url(@legal_case, format: :json), params: { legal_case: {
      outcome: "won",
      outcome_date: "not-a-date"
    } }

    assert_response :unprocessable_entity
    assert_equal "undefined", @legal_case.reload.outcome
  end

  test "does not change an outcome through the general update endpoint" do
    administrator = create_user(role: "admin")

    sign_in(administrator)
    patch legal_case_url(@legal_case), params: { legal_case: { outcome: "won" } }

    assert_redirected_to legal_case_url(@legal_case)
    assert_equal "undefined", @legal_case.reload.outcome
  end

  test "should destroy legal_case" do
    assert_difference("LegalCase.count", -1) do
      delete legal_case_url(@legal_case)
    end

    assert_redirected_to legal_cases_url
  end

  private

  def create_user(role:)
    User.create!(
      office: default_office,
      name: "Usuário #{role}",
      email: "#{role}-#{SecureRandom.hex(4)}@example.com",
      role: role,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def sign_in(user)
    post login_path, params: { email: user.email, password: "segredo123" }
  end
end
