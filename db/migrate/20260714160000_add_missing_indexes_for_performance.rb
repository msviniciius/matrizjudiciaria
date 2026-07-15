class AddMissingIndexesForPerformance < ActiveRecord::Migration[8.1]
  def change
    # tasks - usados em filtros e ordenação
    add_index :tasks, :status
    add_index :tasks, :due_date
    add_index :tasks, :responsible_name

    # deadlines - usados em filtros e ordenação
    add_index :deadlines, :status
    add_index :deadlines, :due_date
    add_index :deadlines, :deadline_type

    # case_events - usado em múltiplas ordenações
    add_index :case_events, :created_at
  end
end
