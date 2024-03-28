class RenameScriptsTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :integration_scripts, :scripts
  end
end
