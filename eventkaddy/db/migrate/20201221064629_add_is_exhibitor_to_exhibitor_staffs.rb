class AddIsExhibitorToExhibitorStaffs < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitor_staffs, :is_exhibitor, :boolean, :default => false
  end
end
