class ProcessType < ApplicationRecord
  belongs_to :legal_area
  has_many :legal_cases, dependent: :nullify

  validates :name, presence: true
  validates :name, uniqueness: { scope: :legal_area_id }
end
