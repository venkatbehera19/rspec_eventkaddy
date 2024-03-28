class AddPortalStylesToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :portal_styles, :json unless column_exists?(:exhibitors, :portal_styles)
  end
end
