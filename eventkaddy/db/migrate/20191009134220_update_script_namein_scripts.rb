class UpdateScriptNameinScripts < ActiveRecord::Migration[4.2]
  def change
   rename_column :scripts, :script_name, :file_name   
  end
end
