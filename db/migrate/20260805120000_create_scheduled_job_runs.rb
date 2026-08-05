class CreateScheduledJobRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_job_runs do |t|
      t.string :job_name, null: false
      t.string :status, null: false
      t.integer :duration_ms, null: false, default: 0
      t.jsonb :result, null: false, default: {}
      t.text :error_message
      t.datetime :started_at, null: false
      t.datetime :finished_at, null: false

      t.timestamps
    end

    add_index :scheduled_job_runs, [ :job_name, :started_at ]
    add_index :scheduled_job_runs, [ :status, :started_at ]
  end
end
