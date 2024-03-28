class AddCurlResultToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :curl_result, :text, :after => :status
  end
end
