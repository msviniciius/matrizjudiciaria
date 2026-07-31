class Unit < ApplicationRecord
  belongs_to :office

  has_many :user_units, dependent: :destroy
  has_many :users, through: :user_units
  has_many :clients, dependent: :nullify
  has_many :legal_cases, dependent: :nullify

  validates :name, :slug, presence: true
  validates :name, uniqueness: { scope: :office_id }
  validates :slug, uniqueness: { scope: :office_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :zip_code, format: { with: /\A\d{5}-?\d{3}\z/, message: "deve estar no formato 00000-000" }, allow_blank: true

  before_validation :normalize_slug

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  private

  def normalize_slug
    self.slug = (slug.presence || name).to_s.parameterize if slug.blank? || name.present?
  end
end
