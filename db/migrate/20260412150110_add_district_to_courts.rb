class AddDistrictToCourts < ActiveRecord::Migration[8.0]
  def change
    add_reference :courts, :district, foreign_key: true
  end
end
