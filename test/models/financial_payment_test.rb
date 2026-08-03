require "test_helper"

class FinancialPaymentTest < ActiveSupport::TestCase
  setup do
    legal_case = create_full_legal_case
    contract = FinancialContract.create!(
      office: default_office,
      legal_case: legal_case,
      fixed_amount: 1_200,
      installment_count: 1,
      total_amount: 1_200
    )
    @installment = contract.installments.create!(number: 1, amount: 1_200, due_date: Date.current)
    @user = create_recording_user
  end

  test "registers one full payment with its proof" do
    paid_at = Time.zone.local(2026, 8, 1, 14, 35)

    payment = @installment.register_payment!(
      amount: 1_200,
      paid_at: paid_at,
      payment_method: "pix",
      recorded_by: @user,
      proof: proof_upload
    )

    assert_equal BigDecimal("1200"), payment.amount
    assert_equal paid_at, payment.paid_at
    assert_equal @user, payment.recorded_by
    assert payment.proof.attached?
    assert @installment.reload.status_paid?
  end

  test "rejects a partial or excessive payment" do
    [ 1_199.99, 1_200.01 ].each do |amount|
      error = assert_raises(ArgumentError) do
        @installment.register_payment!(
          amount: amount,
          paid_at: Time.current,
          payment_method: "cash",
          recorded_by: @user,
          proof: proof_upload
        )
      end

      assert_equal "payment amount must equal installment amount", error.message
      assert_nil @installment.reload.payment
    end
  end

  test "rejects a second payment" do
    register_payment

    error = assert_raises(ArgumentError) do
      register_payment
    end

    assert_equal "installment already paid", error.message
    assert_equal 1, FinancialPayment.where(financial_installment: @installment).count
  end

  test "requires one proof for the payment" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      @installment.register_payment!(
        amount: 1_200,
        paid_at: Time.current,
        payment_method: "pix",
        recorded_by: @user,
        proof: nil
      )
    end

    assert_includes error.record.errors[:proof], "deve ser anexado"
    assert @installment.reload.status_pending?
  end

  test "rejects unsupported payment methods" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      @installment.register_payment!(
        amount: 1_200,
        paid_at: Time.current,
        payment_method: "bank_slip",
        recorded_by: @user,
        proof: proof_upload
      )
    end

    assert_includes error.record.errors[:payment_method], "deve ser informado corretamente"
  end

  test "rejects a recording user from another office" do
    other_office = Office.create!(name: "Escritório externo", slug: "escritorio-externo")
    foreign_user = create_recording_user(office: other_office)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      @installment.register_payment!(
        amount: 1_200,
        paid_at: Time.current,
        payment_method: "debit_card",
        recorded_by: foreign_user,
        proof: proof_upload
      )
    end

    assert_includes error.record.errors[:recorded_by], "não pertence ao escritório atual"
  end

  private

  def register_payment
    @installment.register_payment!(
      amount: 1_200,
      paid_at: Time.current,
      payment_method: "credit_card",
      recorded_by: @user,
      proof: proof_upload
    )
  end

  def create_recording_user(office: default_office)
    User.create!(
      office: office,
      name: "Responsável financeiro",
      email: "financeiro-#{SecureRandom.hex(4)}@example.com",
      role: "associate",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def proof_upload
    {
      io: StringIO.new("comprovante financeiro"),
      filename: "comprovante.txt",
      content_type: "text/plain"
    }
  end
end
