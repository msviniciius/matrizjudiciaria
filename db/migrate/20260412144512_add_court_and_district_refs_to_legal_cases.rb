class AddCourtAndDistrictRefsToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_reference :legal_cases, :court, foreign_key: true
    add_reference :legal_cases, :district, foreign_key: true
  end
end
