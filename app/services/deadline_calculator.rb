class DeadlineCalculator
  def initialize(deadline, today: Date.current)
    @deadline = deadline
    @today = today.to_date
  end

  def recalcular!
    return @deadline unless @deadline.expediente.present?

    ciencia = @deadline.expediente.ciencia
    unless ciencia.present?
      @deadline.update!(start_date: nil, due_date: nil, status: :pending)
      refresh_case_deadline!
      return @deadline
    end

    start_date = business_days.proximo_dia_util(ciencia.data_ciencia + 1.day)
    total_days = @deadline.expediente.quantidade_dias * (@deadline.expediente.prazo_em_dobro? ? 2 : 1)
    due_date = calculate_due_date(start_date, total_days)

    @deadline.update!(start_date: start_date, due_date: due_date, status: status_for(start_date, due_date)) unless @deadline.status_completed? || @deadline.status_suspended?
    refresh_case_deadline!
    @deadline
  end

  private

  def business_days
    @business_days ||= BusinessDaysCalculator.new(reference_date: @today, legal_case: @deadline.legal_case)
  end

  def calculate_due_date(start_date, total_days)
    if @deadline.expediente.contagem == "uteis"
      business_days.somar_dias_uteis(start_date, total_days - 1)
    else
      business_days.proximo_dia_util(start_date + (total_days - 1).days)
    end
  end

  def status_for(start_date, due_date)
    return :overdue if @today > due_date
    return :in_progress if @today >= start_date

    :pending
  end

  def refresh_case_deadline!
    @deadline.legal_case.update_column(:next_deadline_on, @deadline.legal_case.deadlines
      .where(status: %w[pending in_progress extended overdue])
      .where.not(due_date: nil)
      .minimum(:due_date))
  end
end
