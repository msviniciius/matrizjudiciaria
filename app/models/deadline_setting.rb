class DeadlineSetting < ApplicationRecord
  belongs_to :office

  enum :deadline_type, Deadline.deadline_types, prefix: true
  enum :default_priority, Deadline.priorities, prefix: true

  validates :name, :deadline_type, presence: true
  validates :days_to_due, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :deadline_type, uniqueness: { scope: :office_id }
  validates :default_priority, inclusion: { in: Deadline.priorities.keys }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
