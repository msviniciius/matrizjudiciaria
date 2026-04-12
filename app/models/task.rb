class Task < ApplicationRecord
  belongs_to :legal_case

  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed",
    canceled: "canceled"
  }, prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    urgent: "urgent"
  }, prefix: true

  validates :title, :status, presence: true
  validates :status, inclusion: { in: statuses.keys }
  validates :priority, inclusion: { in: priorities.keys }, allow_blank: true
end
