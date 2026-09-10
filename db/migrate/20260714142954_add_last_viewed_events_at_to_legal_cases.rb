class AddLastViewedEventsAtToLegalCases < ActiveRecord::Migration[8.0]
  def change
    add_column :legal_cases, :last_viewed_events_at, :datetime
  end
end
