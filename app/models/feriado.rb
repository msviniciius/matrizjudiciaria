class Feriado < ApplicationRecord
  belongs_to :office, optional: true

  enum :ambito, {
    nacional: "nacional",
    estadual: "estadual",
    municipal: "municipal",
    forense: "forense"
  }, validate: true

  validates :data, :descricao, :ambito, presence: true

  scope :globais, -> { where(office_id: nil) }
  scope :for_office, ->(office) { where(office_id: [ nil, office.id ]) }
end
