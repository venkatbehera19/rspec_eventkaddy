class AddPortalConfigsToExhibitor < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :portal_configs, :json unless column_exists?(:exhibitors, :portal_configs)
  end
end
