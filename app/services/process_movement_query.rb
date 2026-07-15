class ProcessMovementQuery
  attr_reader :scope, :filters

  def initialize(scope, filters = {})
    @scope = scope
    @filters = filters.symbolize_keys
  end

  def call
    apply_search
    apply_phase
    apply_status
    apply_movement_type
    apply_nature
    apply_impact
    apply_origin
    apply_date_range
    apply_responsible
    apply_exam
    apply_administrative_situation
    scope.distinct
  end

  private

  def apply_search
    return if @filters[:q].blank?

    term = "%#{@filters[:q].strip}%"
    @scope = scope.joins(:process).where(
      "COALESCE(process_movements.display_title, '') ILIKE :term
       OR COALESCE(process_movements.complementary_description, '') ILIKE :term
       OR COALESCE(legal_cases.internal_number, '') ILIKE :term
       OR COALESCE(legal_cases.responsible_name, '') ILIKE :term",
      term: term
    )
  end

  def apply_phase
    return if @filters[:phase_id].blank?

    @scope = scope.where(phase_id: @filters[:phase_id])
  end

  def apply_status
    return if @filters[:status].blank?

    @scope = scope.joins(:process).where(legal_cases: { status: @filters[:status] })
  end

  def apply_movement_type
    return if @filters[:movement_type_id].blank?

    @scope = scope.where(movement_type_id: @filters[:movement_type_id])
  end

  def apply_nature
    return if @filters[:nature].blank?

    @scope = scope.where(nature: @filters[:nature])
  end

  def apply_impact
    return if @filters[:impact].blank?

    @scope = scope.where(impact: @filters[:impact])
  end

  def apply_origin
    return if @filters[:origin].blank?

    @scope = scope.where(origin: @filters[:origin])
  end

  def apply_date_range
    if @filters[:from].present?
      @scope = scope.where("event_date >= ?", Time.zone.parse(@filters[:from]).beginning_of_day)
    end

    if @filters[:to].present?
      @scope = scope.where("event_date <= ?", Time.zone.parse(@filters[:to]).end_of_day)
    end
  end

  def apply_responsible
    return if @filters[:responsible_name].blank?

    @scope = scope.joins(:process).where(
      "LOWER(legal_cases.responsible_name) LIKE ?",
      "%#{@filters[:responsible_name].downcase}%"
    )
  end

  def apply_exam
    return if @filters[:exam_id].blank?

    @scope = scope.where(exam_id: @filters[:exam_id])
  end

  def apply_administrative_situation
    return if @filters[:administrative_situation].blank?

    @scope = scope.where(administrative_situation: @filters[:administrative_situation])
  end
end
