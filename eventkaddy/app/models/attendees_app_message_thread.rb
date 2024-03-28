class AttendeesAppMessageThread < ApplicationRecord
  # attr_accessible :attendee_id, :app_message_thread_id, :permanent_hide
  
  belongs_to :attendee
  belongs_to :app_message_thread

  def hide
    update! permanent_hide: true
  end

  # "show" has other meanings in our app, so I think
  # "unhide" is a more revealing method name
  def unhide
    update! permanent_hide: false
  end

  def self.add_recipients(attendee_ids, thread_id, current_attendee_id)
    attendee_ids.each do |a_id|
      result = AttendeesAppMessageThread.where(attendee_id:a_id,app_message_thread_id:thread_id)
      
      if result.length==0
        result.create() do |a|
          if a_id===current_attendee_id
            a.read_status = true
          end
        end
      end   
      true
    end
  end
end
