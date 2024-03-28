class AppMessage < ApplicationRecord
  # attr_accessible :content, :app_message_thread_id, :event_id, :attendee_id, :msg_time

  belongs_to :app_message_thread
  belongs_to :attendee

end
