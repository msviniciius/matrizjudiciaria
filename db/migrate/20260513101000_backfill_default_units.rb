class BackfillDefaultUnits < ActiveRecord::Migration[8.1]
  class Office < ApplicationRecord
    self.table_name = "offices"
  end

  class Unit < ApplicationRecord
    self.table_name = "units"
  end

  class User < ApplicationRecord
    self.table_name = "users"
  end

  class UserUnit < ApplicationRecord
    self.table_name = "user_units"
  end

  class Client < ApplicationRecord
    self.table_name = "clients"
  end

  class LegalCase < ApplicationRecord
    self.table_name = "legal_cases"
  end

  def up
    Office.find_each do |office|
      unit = Unit.find_or_create_by!(office_id: office.id, slug: "matriz") do |u|
        u.name = "Matriz"
        u.active = true
      end

      User.where(office_id: office.id).find_each do |user|
        UserUnit.find_or_create_by!(user_id: user.id, unit_id: unit.id)
      end

      Client.where(office_id: office.id, unit_id: nil).update_all(unit_id: unit.id)
      LegalCase.where(office_id: office.id, unit_id: nil).update_all(unit_id: unit.id)
    end
  end

  def down
    # no-op
  end
end
