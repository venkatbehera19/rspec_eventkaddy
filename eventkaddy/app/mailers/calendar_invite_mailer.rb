require 'digest/sha2'
require 'icalendar'
require 'icalendar/tzinfo'
class CalendarInviteMailer < ActionMailer::Base
  default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def invite(event_id, attendee, attach_calendar_invite = false)
    @event = Event.find event_id
    template = EmailTemplate.email_password_template_for( event_id, "calendar_invitation_email_template" )
    subject  = template.email_subject
    @body = template.render([attendee, @event]) {|content|
      content.gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|

        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))

        # we do not have a choice but to add this extension in the attachments part...
        # the url will otherwise be missing it, and then it won't work in a really confusing way.
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }

    cal = Icalendar::Calendar.new

    begin
      timezone = ActiveSupport::TimeZone[@event.timezone].tzinfo.canonical_zone
      ical_timezone = timezone.ical_timezone @event.event_start_at.localtime(@event.utc_offset)
      cal.add_timezone ical_timezone
    rescue => exception
      puts exception
    end

    cal.prodid = '-//Acme Widgets, Inc.//NONSGML ExportToCalendar//EN'
    cal.version = '2.0'

    description = nil
    organizer = 'support@eventkaddy.com'
    filename = 'invite'
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(@event.event_start_at.localtime(@event.utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.dtend       = Icalendar::Values::DateTime.new(@event.event_end_at.localtime(@event.utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.summary     = @event.name
      if !@event.calendar_json.blank?
        description = ActionController::Base.helpers.strip_tags(JSON.parse(@event.calendar_json)['event_description'])
        organizer   = ActionController::Base.helpers.strip_tags(JSON.parse(@event.calendar_json)['organizer']) || organizer
        filename    = ActionController::Base.helpers.strip_tags(JSON.parse(@event.calendar_json)['filename']) || filename
      end
      e.organizer = organizer
      e.description = description
      e.alarm do |a|
        a.trigger       = "-PT30M"
        a.summary = "Alarm notification"
      end
    end
    cal.publish

    attachments.inline["#{filename}.ics"] = {
      content_type: "text/calendar; charset=UTF-8; method=REQUEST",
      mime_type: 'application/ics',
      content: cal.to_ical,
    }

    message_id_in_header
    if attach_calendar_invite
      mail(
        to: attendee.email,
        subject: subject || "Invitation",
        content_disposition: `attachment; filename="#{filename}.ics"`
      )
    else
      mail(
        to: attendee.email,
        subject: subject || "Invitation",
      )
    end
  end

  def cancel(event, recipient, slot, participant_name)
    subject  = "#{event.name} Meeting with #{participant_name} Canceled"
    @body    = slot.meeting_description.html_safe
    cals = Icalendar::Calendar.parse(slot.calendar_uid)
    cal = cals.first
    cal.append_custom_property 'sequence', '1'
    cal.ip_method='CANCEL'
    event = cal.events.first
    event.status = 'CANCELLED'
    filename = 'invite'

    attachments.inline["#{filename}.ics"] = {
      content_type: "text/calendar; charset=UTF-8; method=CANCEL;",
      mime_type: 'application/ics',
      content: cal.to_ical,
    }

    message_id_in_header
    mail(
      to: recipient.email,
      subject: subject || "Meeting Invite",
      content_disposition: `attachment; filename="#{filename}.ics"`
    )

  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

end
