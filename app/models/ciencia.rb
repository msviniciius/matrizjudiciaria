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
  validate :user_belongs_to_expediente_office

  private

  def user_belongs_to_expediente_office
    return if user.blank? || expediente.blank?
    return if user.office_id == expediente.legal_case.office_id

    errors.add(:user, "deve pertencer ao mesmo escritório do processo")
  end
end
