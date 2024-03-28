class AddCustomContentToExhibitors < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitors, :custom_content, :text
  end
end
