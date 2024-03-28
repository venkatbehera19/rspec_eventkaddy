class AddOriginalFileToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :original_file, :string, :after => :name
  end
end
