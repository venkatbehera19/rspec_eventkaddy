class AddMessagingNotificationsOptOutToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :messaging_notifications_opt_out, :boolean, after: :messaging_opt_out
  end
end
