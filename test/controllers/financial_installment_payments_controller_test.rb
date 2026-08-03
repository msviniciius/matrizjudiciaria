require "test_helper"

class FinancialInstallmentPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_case_dependencies
    @legal_case = create_full_legal_case(internal_number: "PROC-PAGAMENTO-001")
    @user = User.create!(office: default_office, name: "Registrador", email: "registrador-#{SecureRandom.hex(4)}@example.com", role: "associate", password: "segredo123", password_confirmation: "segredo123")
    @contract = FinancialContract.create!(office: default_office, legal_case: @legal_case, fixed_amount: 1_200, installment_count: 1, total_amount: 1_200)
    @installment = @contract.installments.create!(number: 1, amount: 1_200, due_date: Date.current)
    post login_path, params: { email: @user.email, password: "segredo123" }
  end

  test "registers an integral installment payment with proof" do
    assert_difference "FinancialPayment.count", 1 do
      post legal_case_financial_installment_payment_url(@legal_case, @installment, format: :json), params: {
        payment: { paid_at: "2026-08-01T14:35", payment_method: "pix", proof: proof_upload }
      }
    end

    assert_response :success
    payment = @installment.reload.payment
    assert_equal @user, payment.recorded_by
    assert_equal "pix", payment.payment_method
    assert payment.proof.attached?
    assert @installment.status_paid?
    assert_equal "Recebida", response.parsed_body.dig("installments", 0, "status_label")
  end

  test "rejects a second payment and a missing proof" do
    post legal_case_financial_installment_payment_url(@legal_case, @installment, format: :json), params: { payment: { paid_at: "2026-08-01T14:35", payment_method: "cash", proof: proof_upload } }
    assert_response :success

    assert_no_difference "FinancialPayment.count" do
      post legal_case_financial_installment_payment_url(@legal_case, @installment, format: :json), params: { payment: { paid_at: "2026-08-01T14:35", payment_method: "cash" } }
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("error"), "already paid"
  end

  private

  def proof_upload
    Rack::Test::UploadedFile.new(StringIO.new("comprovante"), "text/plain", original_filename: "comprovante.txt")
  end
end
