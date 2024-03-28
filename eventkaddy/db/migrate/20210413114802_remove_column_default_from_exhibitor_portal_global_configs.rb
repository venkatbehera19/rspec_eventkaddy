class RemoveColumnDefaultFromExhibitorPortalGlobalConfigs < ActiveRecord::Migration[4.2]
  def change
    remove_column :exhibitor_portal_global_configs, :default if column_exists?(:exhibitor_portal_global_configs, :default)
  end
end
