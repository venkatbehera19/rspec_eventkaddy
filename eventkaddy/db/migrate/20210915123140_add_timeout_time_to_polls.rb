class AddTimeoutTimeToPolls < ActiveRecord::Migration[6.1]
  def change
    add_column :polls, :timeout_time, :integer unless column_exists?(:polls, :timeout_time)
  end
end
