require "test_helper"

class Receivables::OutcomeTriggerTest < ActiveSupport::TestCase
  test "activates only awaiting case-won receivables for a won case and records its confirmation" do
    legal_case = create_full_legal_case(outcome: "undefined")
    confirming_user = create_confirming_user
    triggered_receivable = create_receivable(
      legal_case: legal_case,
      trigger: "case_won",
      status: "awaiting_trigger",
      amount_paid: 250
    )
    different_trigger = create_receivable(legal_case: legal_case, trigger: "case_started", status: "awaiting_trigger")
    different_trigger_status = different_trigger.status
    different_trigger_triggered_at = different_trigger.triggered_at
    already_active = create_receivable(legal_case: legal_case, trigger: "case_won", status: "pending")
    already_active.update_columns(status: "pending", triggered_at: nil)
    legal_case.update!(outcome: "won")

    Receivables::OutcomeTrigger.call(legal_case: legal_case, confirmed_by: confirming_user)

    assert_equal "pending", triggered_receivable.reload.status
    assert_not_nil triggered_receivable.triggered_at
    assert_equal 250, triggered_receivable.amount_paid

    assert_equal different_trigger_status, different_trigger.reload.status
    assert_equal different_trigger_triggered_at.to_i, different_trigger.triggered_at.to_i
    assert_equal "pending", already_active.reload.status
    assert_nil already_active.triggered_at

    assert_equal confirming_user, legal_case.reload.outcome_confirmed_by
    assert_not_nil legal_case.outcome_confirmed_at
  end

  test "does not activate receivables or confirm a case whose outcome is not won" do
    legal_case = create_full_legal_case(outcome: "lost")
    confirming_user = create_confirming_user
    receivable = create_receivable(legal_case: legal_case, trigger: "case_won", status: "awaiting_trigger")

    Receivables::OutcomeTrigger.call(legal_case: legal_case, confirmed_by: confirming_user)

    assert_equal "awaiting_trigger", receivable.reload.status
    assert_nil receivable.triggered_at
    assert_nil legal_case.reload.outcome_confirmed_by
    assert_nil legal_case.outcome_confirmed_at
  end

  private

  def create_confirming_user
    User.create!(
      office: default_office,
      name: "Administradora Financeira",
      email: "financeiro-#{SecureRandom.hex(4)}@example.com",
      role: "admin",
      password: "segredo123",
      password_confirmation: "segredo123"
    )
  end

  def create_receivable(legal_case:, trigger:, status:, amount_paid: 0)
    Receivable.create!(
      office: default_office,
      legal_case: legal_case,
      description: "Honorários de êxito #{SecureRandom.hex(4)}",
      amount: 1_500,
      amount_paid: amount_paid,
      trigger: trigger,
      status: status
    )
  end
end
