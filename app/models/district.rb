class District < ApplicationRecord
  has_many :legal_cases, dependent: :nullify

  has_many :courts, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
