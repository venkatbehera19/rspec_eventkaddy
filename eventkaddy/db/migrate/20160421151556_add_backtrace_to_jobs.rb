class AddBacktraceToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :backtrace, :text, :after => :warnings
  end
end
