class AddScriptTypeIdtoScripts < ActiveRecord::Migration[4.2]
  def change
    add_column :scripts, :script_type_id, :integer, after: :event_id
  end
end
