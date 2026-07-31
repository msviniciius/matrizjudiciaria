require "test_helper"

class ReceivablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = create_user(role: "admin")
    @attendant = create_user(role: "attendant")
  end

  test "denies access to non-administrators" do
    sign_in(@attendant)

    get receivables_url

    assert_redirected_to root_path
    assert_equal "Apenas administradores podem acessar esta área.", flash[:alert]
  end

  test "shows the receivables navigation to administrators" do
    sign_in(@administrator)

    get receivables_url

    assert_response :success
    assert_includes response.body, "Contas a receber"
    assert_includes response.body, "Aguardando gatilho"
  end

  test "does not expose accounts from another office to an administrator" do
    sign_in(@administrator)
    other_office = create_other_office
    foreign_receivable = create_receivable(office: other_office)

    get edit_receivable_url(foreign_receivable)

    assert_response :not_found
  end

  test "allows an administrator to create receive payment and cancel an account" do
    sign_in(@administrator)

    assert_difference("Receivable.count") do
      post receivables_url, params: { receivable: {
        description: "Honorários contratuais",
        amount: 1_000,
        due_date: Date.current,
        trigger: "manual",
        status: "pending"
      } }
    end

    receivable = Receivable.last
    assert_redirected_to receivables_url
    assert_equal default_office, receivable.office

    patch register_payment_receivable_url(receivable), params: { payment: { value: 300, paid_at: Date.current, payment_method: "pix" } }

    assert_redirected_to receivables_url
    assert_equal "partial", receivable.reload.status
    assert_equal 300, receivable.amount_paid

    patch cancel_receivable_url(receivable)

    assert_redirected_to receivables_url
    assert_equal "canceled", receivable.reload.status
    assert_equal Date.current, receivable.paid_at
  end

  test "does not let an administrator create an unsettled account as received" do
    sign_in(@administrator)

    post receivables_url, params: { receivable: {
      description: "Honorários sem quitação",
      amount: 1_000,
      due_date: Date.current,
      status: "received"
    } }

    receivable = default_office.receivables.find_by!(description: "Honorários sem quitação")
    assert_redirected_to receivables_url
    assert_equal "pending", receivable.status
    assert_equal 0, receivable.amount_paid
  end

  test "inherits client and unit from the selected process" do
    sign_in(@administrator)
    client = create_client(full_name: "Cliente do processo")
    unit = Unit.create!(office: default_office, name: "Unidade do processo", slug: "unidade-processo")
    legal_case = create_full_legal_case(client: client, unit: unit)
    other_client = create_client(full_name: "Cliente incompatível")

    post receivables_url, params: { receivable: {
      description: "Honorários do processo",
      amount: 1_000,
      trigger: "manual",
      legal_case_id: legal_case.id,
      client_id: other_client.id,
      unit_id: nil
    } }

    receivable = default_office.receivables.find_by!(description: "Honorários do processo")
    assert_equal legal_case.id, receivable.legal_case_id
    assert_equal client.id, receivable.client_id
    assert_equal unit.id, receivable.unit_id
  end

  test "rejects a process belonging to another office" do
    sign_in(@administrator)
    other_office = create_other_office
    other_client = Client.create!(office: other_office, full_name: "Cliente externo", cpf_cnpj: SecureRandom.hex(6))
    create_case_dependencies
    foreign_case = create_legal_case(
      office: other_office,
      client: other_client,
      legal_area: @test_legal_area,
      process_type: @test_process_type
    )

    post receivables_url, params: { receivable: {
      description: "Cobrança indevida",
      amount: 1_000,
      trigger: "manual",
      legal_case_id: foreign_case.id
    } }

    assert_response :not_found
    assert_not default_office.receivables.exists?(description: "Cobrança indevida")
  end

  test "allows a receivable linked only to a client" do
    sign_in(@administrator)
    client = create_client(full_name: "Cliente sem processo")

    assert_difference("Receivable.count") do
      post receivables_url, params: { receivable: {
        description: "Consulta avulsa",
        amount: 500,
        trigger: "manual",
        client_id: client.id
      } }
    end

    receivable = default_office.receivables.find_by!(description: "Consulta avulsa")
    assert_nil receivable.legal_case_id
    assert_equal client.id, receivable.client_id
  end

  test "returns process context for administrators" do
    sign_in(@administrator)
    client = create_client(full_name: "Cliente JSON")
    unit = Unit.create!(office: default_office, name: "Unidade JSON", slug: "unidade-json")
    legal_case = create_full_legal_case(client: client, unit: unit)

    get process_context_receivable_url(legal_case), as: :json

    assert_response :success
    payload = response.parsed_body
    assert_equal legal_case.id, payload["legal_case_id"]
    assert_equal client.id, payload["client_id"]
    assert_equal unit.id, payload["unit_id"]
  end

  private

  def create_user(role:)
    User.create!(
      office: default_office,
      name: "Usuário #{role}",
      email: "#{role}-receivables-#{SecureRandom.hex(4)}@example.com",
      role: role,
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def sign_in(user)
    post login_path, params: { email: user.email, password: "segredo123" }
  end

  def create_receivable(office: default_office)
    Receivable.create!(
      office: office,
      description: "Honorários externos",
      amount: 1_000,
      due_date: Date.current,
      status: "pending",
      trigger: "manual"
    )
  end

  def create_other_office
    Office.create!(
      name: "Outro Escritório #{SecureRandom.hex(4)}",
      slug: "outro-escritorio-#{SecureRandom.hex(4)}",
      legal_name: "Outro Escritório",
      default_phase: "atendimento_inicial",
      default_status: "em_analise",
      default_priority: "medium"
    )
  end
end
