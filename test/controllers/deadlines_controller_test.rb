require "test_helper"

class DeadlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    client = Client.create!(full_name: "Cliente Deadline", cpf_cnpj: "33333333333")
    district = District.create!(name: "Imperatriz/MA")
    court = Court.create!(name: "2a Vara Civel", district: district)
    legal_area = LegalArea.create!(name: "Previdenciario", justice_branch: "federal")
    process_type = ProcessType.create!(name: "Acao Previdenciaria", legal_area: legal_area)

    @legal_case = LegalCase.create!(
      internal_number: "PROC-DEA-001",
      phase: "analise_juridica",
      status: "ativo",
      responsible_name: "Advogado da carteira",
      next_action: "Acompanhar prazo do cliente",
      next_deadline_on: Date.current + 6.days,
      client: client,
      legal_area_id: legal_area.id,
      process_type_id: process_type.id,
      district_id: district.id,
      court_id: court.id
    )

    @deadline = Deadline.create!(
      legal_case: @legal_case,
      title: "Prazo teste",
      deadline_type: "judicial",
      start_date: Date.current,
      due_date: Date.current + 5.days,
      status: "pending",
      priority: "medium",
      responsible_name: "Advogado"
    )
  end

  test "should get index" do
    get deadlines_url
    assert_response :success
  end

  test "should get new" do
    get new_deadline_url
    assert_response :success
  end

  test "should create deadline" do
    assert_difference("Deadline.count") do
      post deadlines_url, params: { deadline: {
        legal_case_id: @legal_case.id,
        title: "Novo prazo",
        deadline_type: "appeal",
        start_date: Date.current,
        due_date: Date.current + 7.days,
        status: "pending",
        priority: "high",
        responsible_name: "Equipe"
      } }
    end

    assert_redirected_to deadline_url(Deadline.last)
  end

  test "should show deadline" do
    get deadline_url(@deadline)
    assert_response :success
  end

  test "should get edit" do
    get edit_deadline_url(@deadline)
    assert_response :success
  end

  test "should update deadline" do
    patch deadline_url(@deadline), params: { deadline: { title: "Prazo atualizado", status: "in_progress" } }
    assert_redirected_to deadline_url(@deadline)
  end

  test "should destroy deadline" do
    assert_difference("Deadline.count", -1) do
      delete deadline_url(@deadline)
    end

    assert_redirected_to deadlines_url
  end
end
