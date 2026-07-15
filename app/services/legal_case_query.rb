class LegalCaseQuery
  attr_reader :scope, :filters

  def initialize(scope, filters = {})
    @scope = scope
    @filters = filters.to_h.symbolize_keys
  end

  def call
    apply_search
    apply_phase
    apply_status
    apply_priority
    apply_responsible
    apply_deadline_state
    scope
  end

  private

  def apply_search
    return if @filters[:q].blank?

    term = "%#{@filters[:q].strip}%"
    @scope = scope.joins(:client).where(
      "legal_cases.internal_number ILIKE :term
       OR clients.full_name ILIKE :term
       OR COALESCE(legal_cases.main_subject, '') ILIKE :term
       OR COALESCE(legal_cases.opposing_party, '') ILIKE :term
       OR COALESCE(legal_cases.last_movement, '') ILIKE :term",
      term: term
    )
  end

  def apply_phase
    return if @filters[:phase].blank?

    @scope = scope.where(phase: @filters[:phase])
  end

  def apply_status
    return if @filters[:status].blank?

    @scope = scope.where(status: @filters[:status])
  end

  def apply_priority
    return if @filters[:priority].blank?

    @scope = scope.where(priority: @filters[:priority])
  end

  def apply_responsible
    return if @filters[:responsible_name].blank?

    term = "%#{@filters[:responsible_name].strip}%"
    @scope = scope.where("COALESCE(legal_cases.responsible_name, '') ILIKE ?", term)
  end

  def apply_deadline_state
    case @filters[:deadline_state]
    when "overdue"
      @scope = scope.where("next_deadline_on < ?", Date.current)
    when "today"
      @scope = scope.where(next_deadline_on: Date.current)
    when "upcoming"
      @scope = scope.where(next_deadline_on: Date.current..(Date.current + 7.days))
    when "without_deadline"
      @scope = scope.where(next_deadline_on: nil)
    end
  end
end
