class EnsureNextDeadlineOnOnLegalCases < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:legal_cases, :next_deadline_on)

    add_column :legal_cases, :next_deadline_on, :date
  end
end
