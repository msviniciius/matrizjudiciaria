class Office < ApplicationRecord
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

  def logo_attached?
    logo.attached?
  end

  private

  def normalize_slug
    return if slug.blank? && name.blank?

    self.slug = (slug.presence || name).to_s.parameterize
  end
end
