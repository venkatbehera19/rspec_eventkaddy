class AddCurlResultToAttendeesNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees_notifications, :curl_result, :text, :after => :status
  end
end
