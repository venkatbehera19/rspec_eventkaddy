class AddCalendarInviteToEmailQueues < ActiveRecord::Migration[4.2]
  def change
    add_column :emails_queues, :attach_calendar_invite, :boolean
  end
end
