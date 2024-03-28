class AttendeesAppBadgeTask < ApplicationRecord
  # attr_accessible :app_badge_task_id, :attendee_id, :event_id
  
  belongs_to :app_badge_task
  belongs_to :attendee
end
