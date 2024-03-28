class ChangeIntegerLimitInBackgroundJob < ActiveRecord::Migration[6.1]
  def change
    change_column :background_jobs, :external_job_id, :integer, limit: 8
  end
end
