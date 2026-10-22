class BusinessDaysCalculator
  def initialize(reference_date: Date.current, office: nil, legal_case: nil)
    @reference_date = reference_date.to_date
    @office = office || legal_case&.office
  end

  def dia_util?(date)
    date = normalize_date(date)

    !date.saturday? && !date.sunday? && !feriados.include?(date) && suspensao_dates.none? { |inicio, fim| date.between?(inicio, fim) }
  end

  def proximo_dia_util(date)
    date = normalize_date(date)
    date += 1.day until dia_util?(date)
    date
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

    (start_date..end_date).count { |date| dia_util?(date) }
  end

  private

  def normalize_date(date)
    date.to_date
  end

  def feriados
    @feriados ||= feriados_scope.pluck(:data).to_set
  end

  def suspensao_dates
    @suspensao_dates ||= suspensoes_scope.pluck(:inicio, :fim)
  end

  def feriados_scope
    @office.present? ? Feriado.for_office(@office) : Feriado.globais
  end

  def suspensoes_scope
    @office.present? ? Suspensao.for_office(@office) : Suspensao.globais
  end
end
