xml.instruct!
xml.updates do
  @attendees.each do |attendee|
    xml.update do
      xml.AssociateIDNumber attendee.id
      xml.MeetingBadgeFirstName attendee.first_name
      xml.MeetingBadgeLastName attendee.last_name
      xml.Title attendee.title
      xml.BusinessUnit attendee.business_unit
      xml.WorkPhone attendee.business_phone
      xml.MobilePhone attendee.mobile_phone
      xml.EmailAddress attendee.email
      xml.GeneralSessionSeatingAssignment attendee.assignment
      xml.SessionKeys attendee.iattend_sessions
      xml.walkIn 
    end
  end
end