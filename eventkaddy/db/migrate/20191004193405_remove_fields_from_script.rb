class RemoveFieldsFromScript < ActiveRecord::Migration[4.2]
  def up
    remove_column :scripts, :post_request
    remove_column :scripts, :job
  end

  def change
   # rename_column :scripts, :script_name, :file_name 
   # rename_column :scripts, :file_location, :file_name
  end
end
