class ScheduledJobRun < ApplicationRecord
  STATUSES = %w[success failed].freeze

  validates :job_name, :status, :duration_ms, :started_at, :finished_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :duration_ms, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
