class AddInfoToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :info, :text, :after => :warnings
  end
end
