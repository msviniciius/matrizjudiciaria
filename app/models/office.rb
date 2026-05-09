class Office < ApplicationRecord
  TRIBUNAL_INTEGRATIONS = {
    "TJMA (Tribunal de Justiça do Maranhão)" => "tjma",
    "TRF1 (Tribunal Regional Federal da 1ª Região)" => "trf1",
    "TRF5 (Tribunal Regional Federal da 5ª Região)" => "trf5",
    "TJPI (Tribunal de Justiça do Piauí)" => "tjpi"
  }.freeze

  has_one_attached :logo

  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :legal_cases, dependent: :destroy
  has_many :deadline_settings, dependent: :destroy

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :zip_code, format: { with: /\A\d{5}-?\d{3}\z/, message: "deve estar no formato 00000-000" }, allow_blank: true
  validates :default_phase, inclusion: { in: LegalCase.phases.keys }
  validates :default_status, inclusion: { in: LegalCase.statuses.keys }
  validates :default_priority, inclusion: { in: LegalCase.priorities.keys }
  validates :deadline_alert_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }
  validates :task_alert_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }
  validate :enabled_tribunals_must_be_allowed

  def logo_attached?
    logo.attached?
  end

  def enabled_tribunal_codes
    return [] unless respond_to?(:enabled_tribunals)

    Array(enabled_tribunals).map(&:to_s).reject(&:blank?)
  end

  def tribunal_enabled?(code)
    enabled_tribunal_codes.include?(code.to_s)
  end

  private

  def enabled_tribunals_must_be_allowed
    return unless respond_to?(:enabled_tribunals)

    normalized_codes = Array(enabled_tribunals).map(&:to_s).reject(&:blank?)
    self.enabled_tribunals = normalized_codes

    invalid_codes = normalized_codes - TRIBUNAL_INTEGRATIONS.values
    return if invalid_codes.empty?

    errors.add(:enabled_tribunals, "contém integrações inválidas")
  end

  def normalize_slug
    return if slug.blank? && name.blank?

    self.slug = (slug.presence || name).to_s.parameterize
  end
end
