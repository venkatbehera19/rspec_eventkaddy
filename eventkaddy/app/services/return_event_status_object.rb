class ReturnEventStatusObject

  def initialize(event_id)
    @event_id = event_id
    @status   = {implication:[],todo:[],completed:[],warning:[]}
    @event    = Event.find event_id
  end

  def call
    build_event_status_object
    status
  end

  private

  attr_reader :event_id, :status, :event

  def add_todo(item)
    status[:todo] << item
  end

  def add_completed(item)
    status[:completed] << item
  end

  def add_warning(item)
    status[:warning] << item
  end

  def add_implication(item)
    status[:implication] << item
  end

  def add_urbanairship_status

    notifications = false

    if event.notification_UA_AK
      add_completed 'notification_UA_AK in event table is set.'; notifications = true;
    else
      add_todo 'notification_UA_AK in event table is not yet set.'
    end

    if event.notification_UA_AMS
      add_completed 'notification_UA_AMS in event table is set.'; notifications = true;
    else
      add_todo 'notification_UA_AMS in event table is not yet set.'
    end

    if event.utc_offset
      add_completed 'utc_offset in event table is set.'; notifications = true;
    else
      add_todo 'utc_offset in event table is not yet set.'
    end

    add_implication 'Notifications may not work correctly.' unless notifications
  end

  def return_number_of_other_events_in_multi_event
    Event.where(org_id:event.org_id, multi_event_status:true).size - 1
  end

  def add_multi_event_status

    multi_event = false

    if event.multi_event_status
      add_completed "Event is a multi event with #{return_number_of_other_events_in_multi_event} other events."; multi_event = true;
    else
      add_warning "Event is not a multi event, and will not appear on the multi event page."
    end
  end

  def build_event_status_object
    add_urbanairship_status
    add_multi_event_status
  end

end
