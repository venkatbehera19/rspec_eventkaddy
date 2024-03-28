class AppMessageThread < ApplicationRecord
  # attr_accessible :active, :moderated, :moderator_attendee_id, :title, :event_id

  has_many :app_messages
  has_many :attendees_app_message_threads, :dependent => :destroy
  has_many :attendees, :through => :attendees_app_message_threads 

  def hide_for_all
    attendees_app_message_threads.each {|t| t.hide }
  end

  def unhide_for_all
    attendees_app_message_threads.each {|t| t.unhide }
  end

  def comma_delimited_list_of_participants
    result = []
    self.attendees.each {|a| result << a.full_name}
    result.sort().join(', ')
  end

end

