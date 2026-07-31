class ActivateExistingWonCaseReceivables < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE receivables
      SET status = 'pending', triggered_at = COALESCE(triggered_at, CURRENT_TIMESTAMP)
      WHERE trigger = 'case_won'
        AND status = 'awaiting_trigger'
        AND legal_case_id IN (
          SELECT id FROM legal_cases WHERE outcome = 'won'
        )
    SQL
  end

  def down
    # Activation is intentionally irreversible; the outcome confirmation remains the source of truth.
  end
end
