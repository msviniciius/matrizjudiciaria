class LegalArea < ApplicationRecord
  has_many :process_types, dependent: :destroy
  has_many :legal_cases, dependent: :nullify

  validates :name, :justice_branch, presence: true
  validates :name, uniqueness: { scope: :justice_branch }
end
