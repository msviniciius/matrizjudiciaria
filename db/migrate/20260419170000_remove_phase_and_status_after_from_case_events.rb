class RemovePhaseAndStatusAfterFromCaseEvents < ActiveRecord::Migration[8.0]
  def change
    remove_column :case_events, :phase_after, :string
    remove_column :case_events, :status_after, :string
  end
end
