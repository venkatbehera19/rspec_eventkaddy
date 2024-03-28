require 'digest/sha2'
class GenericMailer < ActionMailer::Base
  default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def new_email email, recipient
    @event = Event.find email.event_id
    @email = email.email
    template = EmailTemplate.find_by id: email.template_id

    @body = template.render([recipient, @event]) {|content|
      content.gsub(/{{event_file\((.*?)\)\.?(.*?)}}/) {|match|

        path = EventFile.find( $1 ).path
        attachments.inline["#{$1}#{File.extname path}"] = File.read( Rails.root.join( 'public' + path ))

        # we do not have a choice but to add this extension in the attachments part...
        # the url will otherwise be missing it, and then it won't work in a really confusing way.
        ActionController::Base.helpers.image_tag attachments["#{$1}#{File.extname path}"].url
      }
    }

    message_id_in_header

    if email.attach_calendar_invite
      filename = 'invite'
      if !@event.calendar_json.blank?
        filename    = ActionController::Base.helpers.strip_tags(JSON.parse(@event.calendar_json)['filename']) || filename
      end
      cal = calendar_invite(@event)
      cal.publish
      attachments.inline["#{filename}.ics"] = {
        content_type: "text/calendar; charset=UTF-8; method=REQUEST",
        mime_type: 'application/ics',
        content: cal.to_ical,
      }
      mail(
        to: @email,
        subject: template.email_subject,
        content_disposition: `attachment; filename="#{filename}.ics"`
      )
    else
      mail(to:@email, subject: template.email_subject )
    end
  end

  def calendar_invite event
    require 'icalendar'
    require 'icalendar/tzinfo'
    cal = Icalendar::Calendar.new

    begin
      timezone = ActiveSupport::TimeZone[event.timezone].tzinfo.canonical_zone
      ical_timezone = timezone.ical_timezone event.event_start_at.localtime(event.utc_offset)
      cal.add_timezone ical_timezone
    rescue => exception
      puts exception
    end

    cal.prodid = '-//Acme Widgets, Inc.//NONSGML ExportToCalendar//EN'
    cal.version = '2.0'

    description = nil
    organizer = 'support@eventkaddy.com'
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(event.event_start_at.localtime(event.utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.dtend       = Icalendar::Values::DateTime.new(event.event_end_at.localtime(event.utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.summary     = event.name
      if !event.calendar_json.blank?
        description = ActionController::Base.helpers.strip_tags(JSON.parse(event.calendar_json)['event_description'])
        organizer   = ActionController::Base.helpers.strip_tags(JSON.parse(event.calendar_json)['organizer']) || organizer
      end
      e.organizer = organizer
      e.description = description
      e.alarm do |a|
        a.trigger       = "-PT30M"
        a.summary = "Alarm notification"
      end
    end
    return cal
  end

  def message_id_in_header(sent_at = Time.now)
    headers["Message-ID"] = "#{Digest::SHA2.hexdigest(sent_at.to_i.to_s)}@eventkaddy.net"
  end

end
