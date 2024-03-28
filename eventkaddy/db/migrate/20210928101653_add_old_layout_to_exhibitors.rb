class AddOldLayoutToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :old_layout, :boolean, default:false unless column_exists?(:exhibitors, :old_layout)
  end
end
