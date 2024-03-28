class AddIsDemoToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :is_demo, :boolean, default: false unless column_exists?(:exhibitors, :is_demo)
    remove_column :exhibitors, :portal_styles, :json if column_exists?(:exhibitors, :portal_styles)
  end
end
