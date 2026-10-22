require "test_helper"

class DeadlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @legal_case = create_full_legal_case(
      internal_number: "PROC-DEA-001",
      responsible_name: "Advogado da carteira",
      next_action: "Acompanhar prazo do cliente"
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

  test "index mounts the React deadlines listing" do
    get deadlines_url

    assert_response :success
    assert_select "#react-deadlines-root"
    assert_select "script[src*='deadlines']"
  end

  test "index JSON exposes deadlines snapshot" do
    get deadlines_url(format: :json), params: { q: "teste", status: "pending" }

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.dig("meta", "total_count")
    assert_equal "teste", body.dig("filters", "q")
    assert_equal "pending", body.dig("filters", "status")
    assert_equal deadlines_path, body.dig("actions", "index")
    assert_equal new_deadline_path, body.dig("actions", "new")

    deadline = body.fetch("deadlines").sole
    assert_equal @deadline.id, deadline.fetch("id")
    assert_equal "PROC-DEA-001", deadline.fetch("process_number")
    assert_equal "Prazo teste", deadline.fetch("title")
    assert_equal deadline_path(@deadline), deadline.fetch("path")
    assert_equal edit_deadline_path(@deadline), deadline.fetch("edit_path")
    assert_equal cumprir_deadline_path(@deadline), deadline.fetch("complete_path")
  end

  test "index only lists deadlines from the active unit" do
    current_unit = Unit.create!(office: default_office, name: "Contencioso prazos")
    other_unit = Unit.create!(office: default_office, name: "Consultivo prazos")
    @legal_case.update!(unit: current_unit)
    other_case = create_full_legal_case(unit: other_unit)
    other_deadline = Deadline.create!(
      legal_case: other_case,
      title: "Prazo de outra unidade",
      due_date: Date.current + 1.day,
      status: "pending"
    )
    sign_in_and_select(current_unit)

    get deadlines_url(format: :json)

    assert_response :success
    deadline_titles = response.parsed_body.fetch("deadlines").map { |deadline| deadline.fetch("title") }
    assert_includes deadline_titles, @deadline.title
    assert_not_includes deadline_titles, other_deadline.title
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

  test "nao cria deadline para processo de outra unidade ativa" do
    current_unit = Unit.create!(office: default_office, name: "Unidade atual criação prazo")
    other_unit = Unit.create!(office: default_office, name: "Outra unidade criação prazo")
    other_case = create_full_legal_case(unit: other_unit)
    sign_in_and_select(current_unit)

    assert_no_difference "Deadline.count" do
      post deadlines_url, params: { deadline: {
        legal_case_id: other_case.id,
        title: "Prazo indevido",
        deadline_type: "internal",
        due_date: Date.current + 3.days,
        status: "pending",
        priority: "medium"
      } }
    end

    assert_response :not_found
  end

  test "permite criar deadline de outra unidade na visao consolidada" do
    other_unit = Unit.create!(office: default_office, name: "Outra unidade visão consolidada")
    other_case = create_full_legal_case(unit: other_unit)
    sign_in_and_select_all_units

    assert_difference "Deadline.count", 1 do
      post deadlines_url, params: { deadline: {
        legal_case_id: other_case.id,
        title: "Prazo consolidado",
        deadline_type: "internal",
        due_date: Date.current + 3.days,
        status: "pending",
        priority: "medium"
      } }
    end

    assert_redirected_to deadline_path(Deadline.order(:id).last)
  end

  test "should show deadline" do
    get deadline_url(@deadline)
    assert_response :success
  end

  test "detalhe do deadline exibe acao de cumprimento" do
    get deadline_url(@deadline, format: :json)

    assert_response :success
    assert_equal @deadline.id, response.parsed_body.fetch("id")
  end

  test "should get edit" do
    get edit_deadline_url(@deadline)
    assert_response :success
  end

  test "should update deadline" do
    patch deadline_url(@deadline), params: { deadline: { title: "Prazo atualizado", status: "in_progress" } }
    assert_redirected_to deadline_url(@deadline)
  end

  test "cumpre deadline e aceita protocolo para prazo de expediente" do
    expediente = @legal_case.expedientes.create!(
      tipo: :intimacao,
      descricao: "Intimação judicial",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :manual
    )
    deadline = expediente.deadline
    expediente.create_ciencia!(tipo: :expressa, data_ciencia: Date.current)
    DeadlineCalculator.new(deadline).recalcular!

    patch "/deadlines/#{deadline.id}/cumprir", params: { protocolo_ref: "PJE-123" }

    assert_redirected_to deadline_path(deadline)
    assert_equal "completed", deadline.reload.status
    assert_equal "PJE-123", deadline.protocolo_ref
  end

  test "cumpre deadline em JSON" do
    patch "/deadlines/#{@deadline.id}/cumprir", params: { protocolo_ref: "IGNORADO" }, as: :json

    assert_response :success
    assert_equal "completed", response.parsed_body.fetch("status")
  end

  test "cumpre deadline manual sem alterar o fluxo de protocolo" do
    patch "/deadlines/#{@deadline.id}/cumprir", params: { protocolo_ref: "IGNORADO" }

    assert_redirected_to deadline_path(@deadline)
    assert_equal "completed", @deadline.reload.status
    assert_nil @deadline.protocolo_ref
  end

  test "rejeita cumprimento de deadline de outro escritorio" do
    other_office = Office.create!(
      name: "Other Office Cumprir", slug: "other-office-cumprir", default_phase: "atendimento_inicial",
      default_status: "em_analise", default_priority: "medium"
    )
    other_client = Client.create!(full_name: "Outro cliente", cpf_cnpj: SecureRandom.hex(6), office: other_office)
    other_case = LegalCase.create!(
      internal_number: "PROC-CUMPRIR-OTHER", phase: "analise_juridica", status: "em_analise",
      responsible_name: "Outro advogado", next_action: "Acompanhar", next_deadline_on: Date.current + 3.days,
      client: other_client, office: other_office, legal_area: @legal_case.legal_area,
      process_type: @legal_case.process_type, district: @legal_case.district, court: @legal_case.court
    )
    deadline = Deadline.create!(
      legal_case: other_case, title: "Prazo externo", deadline_type: "internal",
      status: "pending", due_date: Date.current + 2.days
    )

    patch "/deadlines/#{deadline.id}/cumprir", params: { protocolo_ref: "PJE-EXTERNO" }

    assert_response :not_found
    assert_equal "pending", deadline.reload.status
  end

  test "rejeita cumprimento de deadline fora da unidade ativa" do
    current_unit = Unit.create!(office: default_office, name: "Unidade atual cumprir")
    other_unit = Unit.create!(office: default_office, name: "Outra unidade cumprir")
    other_case = create_full_legal_case(unit: other_unit)
    deadline = Deadline.create!(
      legal_case: other_case, title: "Prazo de outra unidade", deadline_type: "internal",
      status: "pending", due_date: Date.current + 2.days
    )
    sign_in_and_select(current_unit)

    patch "/deadlines/#{deadline.id}/cumprir", params: { protocolo_ref: "PJE-UNIDADE" }

    assert_response :not_found
    assert_equal "pending", deadline.reload.status
  end

  test "nao permite editar vencimento de deadline juridico originado por expediente" do
    expediente = @legal_case.expedientes.create!(
      tipo: :intimacao,
      descricao: "Intimação judicial",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :manual
    )
    deadline = expediente.deadline
    deadline.update!(start_date: Date.current, due_date: Date.current + 5.days)

    patch deadline_url(deadline), params: { deadline: { title: "Descrição atualizada", due_date: Date.current + 30.days } }

    assert_redirected_to deadline_url(deadline)
    assert_equal "Descrição atualizada", deadline.reload.title
    assert_equal Date.current + 5.days, deadline.due_date
  end

  test "rejeita extensao manual de deadline juridico originado por expediente" do
    expediente = @legal_case.expedientes.create!(
      tipo: :intimacao,
      descricao: "Intimação judicial",
      data_disponibilizacao: Date.current,
      quantidade_dias: 5,
      contagem: :uteis,
      prazo_em_dobro: false,
      origem: :manual
    )
    deadline = expediente.deadline
    original_due_date = Date.current + 5.days
    deadline.update!(start_date: Date.current, due_date: original_due_date)

    patch quick_update_deadline_path(deadline), params: { action_kind: "extended", extended_to: Date.current + 30.days }

    assert_redirected_to deadlines_path
    assert_equal original_due_date, deadline.reload.due_date
    assert_equal "pending", deadline.status
  end

  test "mantem extensao manual para deadline sem expediente" do
    extended_to = Date.current + 30.days

    patch quick_update_deadline_path(@deadline), params: { action_kind: "extended", extended_to: extended_to }

    assert_redirected_to deadlines_path
    assert_equal "extended", @deadline.reload.status
    assert_equal extended_to, @deadline.due_date
    assert_equal Date.current + 5.days, @deadline.extended_from_date
  end

  test "nao permite reatribuir deadline a processo de outro escritorio" do
    other_office = Office.create!(
      name: "Other Office", slug: "other-office", default_phase: "atendimento_inicial",
      default_status: "em_analise", default_priority: "medium"
    )
    other_client = Client.create!(full_name: "Outro cliente", cpf_cnpj: SecureRandom.hex(6), office: other_office)
    other_case = LegalCase.create!(
      internal_number: "PROC-OTHER-001", phase: "analise_juridica", status: "em_analise",
      responsible_name: "Outro advogado", next_action: "Acompanhar", next_deadline_on: Date.current + 3.days,
      client: other_client, office: other_office, legal_area: @legal_case.legal_area,
      process_type: @legal_case.process_type, district: @legal_case.district, court: @legal_case.court
    )

    patch deadline_url(@deadline), params: { deadline: { legal_case_id: other_case.id, title: "Atualizado" } }

    assert_redirected_to deadline_url(@deadline)
    assert_equal @legal_case.id, @deadline.reload.legal_case_id
    assert_equal "Atualizado", @deadline.title
  end

  test "should destroy deadline" do
    assert_difference("Deadline.count", -1) do
      delete deadline_url(@deadline)
    end

    assert_redirected_to deadlines_url
  end

  private

  def sign_in_and_select(unit)
    admin = User.create!(
      office: default_office,
      name: "Admin prazos",
      email: "admin-prazos-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: unit.id }
  end

  def sign_in_and_select_all_units
    admin = User.create!(
      office: default_office,
      name: "Admin visão consolidada",
      email: "admin-consolidado-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    post login_path, params: { email: admin.email, password: "segredo123" }
    post unit_session_path, params: { all_units: "1" }
  end
end
