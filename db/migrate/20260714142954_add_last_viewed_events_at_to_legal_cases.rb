class AddLastViewedEventsAtToLegalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_cases, :last_viewed_events_at, :datetime
  end
end
