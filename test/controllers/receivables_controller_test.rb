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
