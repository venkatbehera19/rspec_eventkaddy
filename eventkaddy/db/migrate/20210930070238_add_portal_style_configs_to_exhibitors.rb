class AddPortalStyleConfigsToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :portal_style_configs, :json
  end
end
