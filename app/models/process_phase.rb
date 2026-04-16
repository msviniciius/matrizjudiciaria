class ProcessPhase < ApplicationRecord
  has_many :movement_templates, foreign_key: :phase_id, dependent: :restrict_with_exception
  has_many :process_movements, foreign_key: :phase_id, dependent: :restrict_with_exception
  has_many :next_movement_templates, class_name: "MovementTemplate", foreign_key: :next_phase_id, dependent: :restrict_with_exception
  has_many :next_process_movements, class_name: "ProcessMovement", foreign_key: :next_phase_id, dependent: :restrict_with_exception

  validates :code, :name, presence: true
  validates :code, uniqueness: true
end
