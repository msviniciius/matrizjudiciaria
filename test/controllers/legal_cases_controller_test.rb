require "test_helper"

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
      status: "ativo",
      responsible_name: "Advogado",
      claim_value: 1000,
      priority: "medium",
      client: @client,
      legal_area_id: @legal_area.id,
      process_type_id: @process_type.id,
      district_id: @district.id,
      court_id: @court.id
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
        status: "ativo",
        responsible_name: "Advogado",
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

  test "should destroy legal_case" do
    assert_difference("LegalCase.count", -1) do
      delete legal_case_url(@legal_case)
    end

    assert_redirected_to legal_cases_url
  end
end
