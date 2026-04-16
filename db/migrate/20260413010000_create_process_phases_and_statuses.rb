class CreateProcessPhasesAndStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :process_phases do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.integer :order, null: false, default: 0

      t.timestamps
    end

    add_index :process_phases, :code, unique: true
    add_index :process_phases, [ :active, :order ]

    create_table :process_statuses do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.integer :order, null: false, default: 0

      t.timestamps
    end

    add_index :process_statuses, :code, unique: true
    add_index :process_statuses, [ :active, :order ]
  end
end
