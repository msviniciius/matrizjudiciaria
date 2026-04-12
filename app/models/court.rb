class Court < ApplicationRecord
  has_many :legal_cases, dependent: :nullify

  belongs_to :district, optional: true

  validates :name, presence: true, uniqueness: { scope: :district_id }
end
