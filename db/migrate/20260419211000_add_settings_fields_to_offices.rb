class AddSettingsFieldsToOffices < ActiveRecord::Migration[8.1]
  def change
    change_table :offices, bulk: true do |t|
      t.string :legal_name
      t.string :cnpj
      t.string :oab_registration
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :primary_color, default: "#112f4e", null: false
      t.string :secondary_color, default: "#b08a45", null: false
      t.string :default_phase, default: "atendimento_inicial", null: false
      t.string :default_status, default: "em_analise", null: false
      t.string :default_priority, default: "medium", null: false
      t.integer :deadline_alert_days, default: 7, null: false
      t.integer :task_alert_days, default: 7, null: false
    end

    add_index :offices, :cnpj
    add_index :offices, :email
  end
end
