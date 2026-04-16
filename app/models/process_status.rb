class ProcessStatus < ApplicationRecord
  validates :code, :name, presence: true
  validates :code, uniqueness: true
end
