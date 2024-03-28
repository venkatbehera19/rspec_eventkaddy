class AddSessionIdToAppMessageThreads < ActiveRecord::Migration[4.2]
  def change
    add_column :app_message_threads, :session_id, :integer, :after => :moderator_attendee_id
  end
end
