class AddWarningsToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :warnings, :text, :after => :error_message
  end
end
