class AddDefaultValueToPollsTimeoutTime < ActiveRecord::Migration[6.1]
  def change
    change_column :polls, :timeout_time, :integer, default: 30
  end
end
