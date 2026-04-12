class AddDistrictToCourts < ActiveRecord::Migration[8.1]
  def change
    add_reference :courts, :district, foreign_key: true
  end
end
