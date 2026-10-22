class BusinessDaysCalculator
  CALENDAR_WINDOW_DAYS = 31

  def initialize(reference_date: Date.current, office: nil, legal_case: nil)
    @reference_date = reference_date.to_date
    @office = office || legal_case&.office
    @feriados = Set.new
    @suspensao_dates = []
    @calendar_loaded_from = nil
    @calendar_loaded_to = nil
  end

  def dia_util?(date)
    date = normalize_date(date)
    ensure_calendar_loaded(date, date)

    business_day_loaded?(date)
  end

  def proximo_dia_util(date)
    date = normalize_date(date)

    loop do
      ensure_calendar_loaded(date, date + CALENDAR_WINDOW_DAYS.days)
      while date <= @calendar_loaded_to
        return date if business_day_loaded?(date)

        date += 1.day
      end
    end
  end

  def somar_dias_uteis(date, number)
    date = normalize_date(date)
    number = Integer(number)
    raise ArgumentError, "number deve ser maior ou igual a zero" if number.negative?

    number.times { date = proximo_dia_util(date + 1.day) }
    date
  end

  def dias_uteis_entre(start_date, end_date)
    start_date = normalize_date(start_date)
    end_date = normalize_date(end_date)
    return 0 if end_date < start_date

    ensure_calendar_loaded(start_date, end_date)
    (start_date..end_date).count { |date| business_day_loaded?(date) }
  end

  private

  def normalize_date(date = @reference_date)
    date.to_date
  end

  def business_day_loaded?(date)
    !date.saturday? && !date.sunday? && !@feriados.include?(date) && @suspensao_dates.none? { |inicio, fim| date.between?(inicio, fim) }
  end

  def ensure_calendar_loaded(start_date, end_date)
    return if start_date > end_date

    ranges_to_load = if @calendar_loaded_from.nil?
      [ [ start_date, end_date ] ]
    else
      [].tap do |ranges|
        ranges << [ start_date, @calendar_loaded_from - 1.day ] if start_date < @calendar_loaded_from
        ranges << [ @calendar_loaded_to + 1.day, end_date ] if end_date > @calendar_loaded_to
      end
    end

    ranges_to_load.each { |range_start, range_end| load_calendar_range(range_start, range_end) }
    @calendar_loaded_from = [ @calendar_loaded_from, start_date ].compact.min
    @calendar_loaded_to = [ @calendar_loaded_to, end_date ].compact.max
  end

  def load_calendar_range(start_date, end_date)
    @feriados.merge(feriados_scope.where(data: start_date..end_date).pluck(:data))
    suspensoes_scope
      .where("inicio <= ? AND fim >= ?", end_date, start_date)
      .pluck(:inicio, :fim)
      .each { |interval| @suspensao_dates << interval unless @suspensao_dates.include?(interval) }
  end

  def feriados_scope
    @office.present? ? Feriado.for_office(@office) : Feriado.globais
  end

  def suspensoes_scope
    @office.present? ? Suspensao.for_office(@office) : Suspensao.globais
  end
end
