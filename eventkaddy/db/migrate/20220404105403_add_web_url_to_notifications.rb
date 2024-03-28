class AddWebUrlToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :web_url, :string
  end
end
