class MovementType < ApplicationRecord
  has_many :case_events, dependent: :restrict_with_exception
  has_many :movement_templates, dependent: :restrict_with_exception
  has_many :process_movements, dependent: :restrict_with_exception

  validates :name, :code, presence: true
  validates :name, :code, uniqueness: true
end
