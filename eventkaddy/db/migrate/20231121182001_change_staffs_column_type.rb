class ChangeStaffsColumnType < ActiveRecord::Migration[6.1]
  def change
    change_column :exhibitors, :staffs, :text, size: :long, collation: "utf8mb4_bin"
  end
end
