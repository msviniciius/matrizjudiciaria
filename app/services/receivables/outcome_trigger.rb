module Receivables
  class OutcomeTrigger
    def self.call(legal_case:, confirmed_by:)
      new(legal_case: legal_case, confirmed_by: confirmed_by).call
    end

    def initialize(legal_case:, confirmed_by:)
      @legal_case = legal_case
      @confirmed_by = confirmed_by
    end

    def call
      return unless @legal_case.outcome_won?

      LegalCase.transaction do
        @legal_case.update!(
          outcome_confirmed_by: @confirmed_by,
          outcome_confirmed_at: Time.current
        )
        @legal_case.receivables.awaiting_case_won_trigger.find_each(&:activate!)
      end
    end
  end
end
