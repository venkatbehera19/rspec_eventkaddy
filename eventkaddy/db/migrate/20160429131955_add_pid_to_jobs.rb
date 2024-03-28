class AddPidToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :pid, :integer, :after => :event_id
  end
end
