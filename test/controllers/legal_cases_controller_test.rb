require "test_helper"
require "rack/utils"
require "uri"

class LegalCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(full_name: "Cliente Base", cpf_cnpj: "11111111111")
    @district = District.create!(name: "Sao Luis/MA")
    @court = Court.create!(name: "1a Vara Civel", district: @district)
    @legal_area = LegalArea.create!(name: "Civel", justice_branch: "state")
    @process_type = ProcessType.create!(name: "Procedimento Comum", legal_area: @legal_area)

    @legal_case = LegalCase.create!(
      internal_number: "PROC-BASE-001",
      external_number: "0000001-00.2026.8.10.0001",
      entry_date: Date.current,
      protocol_date: Date.current,
      subarea: "Subarea",
      main_subject: "Assunto",
      phase: "analise_juridica",
      status: "em_analise",
      responsible_name: "Advogado",
      next_action: "Revisar documentação inicial",
      next_deadline_on: Date.current + 5.days,
      claim_value: 1000,
      priority: "medium",
      client: @client,
      legal_area_id: @legal_area.id,
      process_type_id: @process_type.id,
      district_id: @district.id,
      court_id: @court.id
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
        legal_area_id: @legal_area.id,
        process_type_id: @process_type.id,
        district_id: @district.id,
        court_id: @court.id
      } }
    end

    assert_redirected_to legal_case_url(LegalCase.last)
  end

  test "should show legal_case" do
    get legal_case_url(@legal_case)
    assert_response :success
  end

  test "should get daily closure" do
    get daily_closure_legal_cases_url
    assert_response :success
  end

  test "should export process calendar in ics format" do
    get calendar_legal_case_url(@legal_case, format: :ics)
    assert_response :success
    assert_equal "text/calendar", @response.media_type
    assert_includes @response.body, "BEGIN:VCALENDAR"
    assert_includes @response.body, @legal_case.internal_number
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
      legal_area_id: @legal_area.id,
      process_type_id: @process_type.id,
      district_id: @district.id,
      court_id: @court.id,
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

  test "should destroy legal_case" do
    assert_difference("LegalCase.count", -1) do
      delete legal_case_url(@legal_case)
    end

    assert_redirected_to legal_cases_url
  end
end
