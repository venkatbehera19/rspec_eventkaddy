class AddColumnStaffsToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :staffs, :json
  end
end
