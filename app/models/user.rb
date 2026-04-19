require "digest"
require "securerandom"

class User < ApplicationRecord
  belongs_to :office

  ROLES = %w[admin attendant].freeze

  attr_reader :password

  validates :name, :email, :role, presence: true
  validates :email, uniqueness: { scope: :office_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validate :password_confirmation_matches

  before_validation :normalize_email
  before_validation :ensure_password_data_for_create, on: :create

  scope :active, -> { where(active: true) }

  def admin?
    role == "admin"
  end

  def attendant?
    role == "attendant"
  end

  def password=(value)
    @password = value
    return if value.blank?

    self.password_salt = SecureRandom.hex(16)
    self.password_digest = self.class.digest_for(password_salt, value)
  end

  def password_confirmation=(value)
    @password_confirmation = value
  end

  def authenticate(raw_password)
    return false if raw_password.blank? || password_digest.blank? || password_salt.blank?

    expected = self.class.digest_for(password_salt, raw_password)
    ActiveSupport::SecurityUtils.secure_compare(password_digest, expected)
  end

  def record_sign_in!
    update_column(:last_sign_in_at, Time.current)
  end

  def self.digest_for(salt, raw_password)
    Digest::SHA256.hexdigest("#{salt}--#{raw_password}")
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def ensure_password_data_for_create
    return if password_digest.present? && password_salt.present?
    return if @password.present?

    errors.add(:password, :blank)
  end

  def password_confirmation_matches
    return if @password.blank?
    return if @password_confirmation.to_s == @password

    errors.add(:password_confirmation, "não confere com a senha")
  end
end
