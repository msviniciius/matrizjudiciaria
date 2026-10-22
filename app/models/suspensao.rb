class Suspensao < ApplicationRecord
  self.table_name = "suspensoes"

  belongs_to :office, optional: true

  validates :inicio, :fim, :descricao, presence: true
  validates :fim, comparison: { greater_than_or_equal_to: :inicio }, if: -> { inicio.present? && fim.present? }

  scope :globais, -> { where(office_id: nil) }
  scope :for_office, ->(office) { where(office_id: [ nil, office.id ]) }
end
