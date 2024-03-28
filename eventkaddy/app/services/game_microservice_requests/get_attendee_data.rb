class GetAttendeeData < GetGame

  def post_initialize(event_id)
    @event_id = event_id
  end

  private

  attr_reader :event_id

  def params
    "/attendee_data?event_id=#{event_id}"
  end

end
