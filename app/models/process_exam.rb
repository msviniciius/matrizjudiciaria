class ProcessExam < ApplicationRecord
  belongs_to :legal_case

  has_many :case_events, dependent: :nullify
  has_many :process_movements, foreign_key: :exam_id, dependent: :nullify

  scope :active, -> { where(active: true) }

  enum :exam_nature, {
    medica: "medica",
    social: "social",
    socioeconomica: "socioeconomica",
    tecnica: "tecnica",
    outra: "outra"
  }, prefix: true

  enum :exam_scope, {
    judicial: "judicial",
    administrativa: "administrativa"
  }, prefix: true

  enum :status, {
    nao_designada: "nao_designada",
    designada: "designada",
    realizada: "realizada",
    cancelada: "cancelada",
    redesignada: "redesignada",
    laudo_pendente: "laudo_pendente",
    laudo_juntado: "laudo_juntado",
    resultado_disponibilizado: "resultado_disponibilizado"
  }, prefix: true

  validates :exam_nature, :exam_scope, :status, presence: true

  def summary_label
    nature = exam_nature.to_s.humanize
    scope = exam_scope.to_s.humanize
    when_text = scheduled_at.present? ? I18n.l(scheduled_at, format: :short) : "sem data designada"
    "#{nature} (#{scope}) - #{when_text}"
  end

  def scheduled_label
    return "sem data designada" if scheduled_at.blank?

    I18n.l(scheduled_at, format: :short)
  end

  def near_schedule?(days = 10)
    return false if scheduled_at.blank?

    date = scheduled_at.to_date
    date >= Date.current && date <= Date.current + days.days
  end
end
