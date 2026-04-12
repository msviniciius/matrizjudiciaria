class LegalCase < ApplicationRecord
  belongs_to :client
  belongs_to :legal_area, optional: true
  belongs_to :process_type, optional: true
  belongs_to :court, optional: true
  belongs_to :district, optional: true

  has_many :case_events, dependent: :destroy
  has_many :deadlines, dependent: :destroy
  has_many :tasks, dependent: :destroy

  enum :status, {
    active: "active",
    on_hold: "on_hold",
    completed: "completed",
    archived: "archived"
  }, prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    urgent: "urgent"
  }, prefix: true

  enum :phase, {
    intake: "intake",
    analysis: "analysis",
    filing: "filing",
    instruction: "instruction",
    judgment: "judgment",
    appeal: "appeal",
    enforcement: "enforcement",
    closed: "closed"
  }, prefix: true

  validates :internal_number, :legal_area_id, :process_type_id, :court_id, :district_id, :phase, :status, presence: true
  validates :internal_number, uniqueness: true
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
  validates :phase, inclusion: { in: phases.keys }
end
