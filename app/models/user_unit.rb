class UserUnit < ApplicationRecord
  belongs_to :user
  belongs_to :unit

  validates :user_id, uniqueness: { scope: :unit_id }
  validate :unit_belongs_to_user_office

  private

  def unit_belongs_to_user_office
    return if user.blank? || unit.blank?
    return if user.office_id == unit.office_id

    errors.add(:unit, "deve pertencer ao mesmo escritório do usuário")
  end
end
