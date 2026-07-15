class RemoveLegacyStringColumnsFromLegalCases < ActiveRecord::Migration[8.1]
  def change
    # Colunas string legadas, substituídas por FKs (court_id, district_id, etc.)
    # As associações belongs_to sombreiam estas colunas, tornando-as inacessíveis
    # via accessors normais — são código morto.
    remove_column :legal_cases, :court, :string
    remove_column :legal_cases, :district, :string
    remove_column :legal_cases, :legal_area, :string
    remove_column :legal_cases, :process_type, :string
  end
end
