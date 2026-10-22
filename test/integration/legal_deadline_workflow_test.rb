require "test_helper"

class LegalDeadlineWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @office = default_office
    @unit = Unit.create!(office: @office, name: "Contencioso fluxo completo")
    @admin = User.create!(
      office: @office,
      name: "Admin fluxo completo",
      email: "admin-fluxo-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
    @legal_case = create_full_legal_case(
      internal_number: "PROC-FLUXO-001",
      unit: @unit,
      responsible_name: "Advogado do fluxo"
    )

    post login_path, params: { email: @admin.email, password: "segredo123" }
    post unit_session_path, params: { unit_id: @unit.id }
  end

  test "integra expediente, ciencia, calculo e painel" do
    post expedientes_path, params: {
      expediente: {
        legal_case_id: @legal_case.id,
        tipo: "intimacao",
        descricao: "Intimação para manifestação",
        data_disponibilizacao: Date.current,
        quantidade_dias: 3,
        contagem: "uteis",
        prazo_em_dobro: false,
        origem: "manual"
      }
    }, as: :json

    assert_response :created
    expediente = @legal_case.expedientes.order(:id).last
    assert_equal "pending", expediente.deadline.status
    assert_nil expediente.deadline.due_date

    post ciencias_path, params: {
      ciencia: {
        expediente_id: expediente.id,
        tipo: "expressa",
        data_ciencia: Date.current
      }
    }, as: :json

    assert_response :created
    expediente.reload
    deadline = expediente.deadline
    assert_equal "expressa", expediente.ciencia.tipo
    assert_equal Date.current, expediente.ciencia.data_ciencia
    assert_operator deadline.start_date, :>, expediente.ciencia.data_ciencia
    assert_operator deadline.due_date, :>=, deadline.start_date
    assert_includes %w[pending in_progress], deadline.status
    assert_equal deadline.due_date, @legal_case.reload.next_deadline_on

    get painel_path(format: :json)

    assert_response :success
    dashboard_deadline = response.parsed_body.fetch("deadline_boxes").values
      .flat_map { |box| box.fetch("items") }
      .find { |item| item.fetch("id") == deadline.id }

    assert_not_nil dashboard_deadline
    assert_equal @legal_case.internal_number, dashboard_deadline.fetch("legal_case_number")
    assert_equal expediente.id, dashboard_deadline.fetch("expediente_id")
    assert_equal Date.current.iso8601, dashboard_deadline.fetch("science_date")
    assert_equal "manual", dashboard_deadline.fetch("origin")
    assert_includes %w[in_progress overdue], dashboard_deadline.fetch("legal_state")
  end
end
