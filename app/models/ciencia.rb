class Ciencia < ApplicationRecord
  self.table_name = "ciencias"

  belongs_to :expediente
  belongs_to :user, optional: true

  enum :tipo, {
    expressa: "expressa",
    tacita: "tacita"
  }, validate: true

  validates :tipo, :data_ciencia, presence: true
  validates :expediente, uniqueness: true
end
