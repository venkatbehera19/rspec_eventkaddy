class AddColumnsToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :contact_name, :string
    add_column :exhibitors, :contact_title, :string
    add_column :exhibitors, :toll_free, :string
  end
end
