class RefreshPrazosJob < ApplicationJob
  queue_as :default

  DEFAULT_READING_PERIOD_DAYS = 10
  OPEN_STATUSES = %w[pending in_progress overdue extended].freeze

  def self.perform(params = {})
    perform_now(params)
  end

  def perform(params = {})
    today = parse_date(params[:today] || Date.current)
    deadlines = open_deadlines(params[:office_id])
    result = { processed: 0, tacit_acknowledgements: 0 }

    deadlines.find_each do |deadline|
      ciencia = create_tacit_acknowledgement!(deadline, today)
      result[:tacit_acknowledgements] += 1 if ciencia&.tacita?
      DeadlineCalculator.new(deadline, today: today).recalcular!
      result[:processed] += 1
    end

    result
  end

  private

  def open_deadlines(office_id)
    scope = Deadline
      .joins(:expediente, :legal_case)
      .where(status: OPEN_STATUSES)
      .includes(:expediente, legal_case: :office)

    office_id.present? ? scope.where(legal_cases: { office_id: office_id }) : scope
  end

  def create_tacit_acknowledgement!(deadline, today)
    expediente = deadline.expediente
    return expediente.ciencia if expediente.ciencia.present?
    return unless today >= tacit_acknowledgement_date(expediente)

    expediente.create_ciencia!(tipo: :tacita, data_ciencia: tacit_acknowledgement_date(expediente))
  rescue ActiveRecord::RecordNotUnique
    expediente.reload.ciencia
  end

  def tacit_acknowledgement_date(expediente)
    expediente.data_disponibilizacao + reading_period_days.days
  end

  def reading_period_days
    Integer(ENV.fetch("LEGAL_EXPEDIENTE_READING_DAYS", DEFAULT_READING_PERIOD_DAYS))
  end

  def parse_date(value)
    value.respond_to?(:to_date) ? value.to_date : Date.parse(value.to_s)
  end
end
