class AddUrlTiktokToExhibitors < ActiveRecord::Migration[6.1]
  def change
    add_column :exhibitors, :url_tiktok, :string unless column_exists?(:exhibitors, :url_tiktok)
  end
end
