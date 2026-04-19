class AddOfficeToLegalCases < ActiveRecord::Migration[8.1]
  class MigrationOffice < ApplicationRecord
    self.table_name = "offices"
  end

  class MigrationLegalCase < ApplicationRecord
    self.table_name = "legal_cases"
  end

  def change
    add_reference :legal_cases, :office, foreign_key: true

    reversible do |dir|
      dir.up do
        default_office = MigrationOffice.find_or_create_by!(slug: "default") do |office|
          office.name = "Kayran Advocacia"
        end

        MigrationLegalCase.where(office_id: nil).update_all(office_id: default_office.id)
        change_column_null :legal_cases, :office_id, false
      end
    end
  end
end
