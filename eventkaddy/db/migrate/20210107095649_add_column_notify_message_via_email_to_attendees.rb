class AddColumnNotifyMessageViaEmailToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :notify_message_via_email, :boolean, :default=>true
  end
end
