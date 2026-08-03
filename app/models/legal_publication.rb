class LegalPublication < ApplicationRecord
  belongs_to :office
  belongs_to :legal_case, optional: true

  validates :source, :external_id, :event_name, :content, presence: true
  validates :external_id, uniqueness: { scope: :source }

  scope :recent, -> { order(Arel.sql("published_at DESC NULLS LAST"), created_at: :desc, id: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :linked, -> { where.not(legal_case_id: nil) }
  scope :unlinked, -> { where(legal_case_id: nil) }

  def mark_read!
    update!(read_at: Time.current) if read_at.blank?
  end

  def link_matching_legal_case
    return if office.blank? || process_number.blank?

    normalized_process_number = self.class.normalize_process_number(process_number)
    return if normalized_process_number.blank?

    matches = office.legal_cases
      .where("REGEXP_REPLACE(COALESCE(external_number, ''), '\\D', '', 'g') = ?", normalized_process_number)
      .limit(2)
      .to_a

    self.legal_case = matches.first if matches.one?
  end

  def self.normalize_process_number(value)
    value.to_s.gsub(/\D/, "")
  end
end
