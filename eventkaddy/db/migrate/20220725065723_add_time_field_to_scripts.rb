class AddTimeFieldToScripts < ActiveRecord::Migration[6.1]
  def change
    add_column :scripts, :run_start_at, :datetime
    add_column :scripts, :run_till, :datetime
    add_column :scripts, :run_at_intervals, :string
  end
end
