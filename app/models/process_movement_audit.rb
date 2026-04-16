class ProcessMovementAudit < ApplicationRecord
  belongs_to :process_movement

  validates :action, presence: true
end
