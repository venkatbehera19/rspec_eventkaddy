require 'digest/sha2'
class OrganizationMailer < ActionMailer::Base
  default from: "support@eventkaddy.net"

  def mail(headers = {}, &block)
    headers[:from] = "#{@event.mailer_name ? @event.mailer_name : @event.name ? @event.name : 'Support'} <support@eventkaddy.net>"
    super(headers, &block)
  end

  def new_email email
    @user = email.user
    @email = email.email
    template = OrganizationEmailTemplate.find_by id: email.organization_email_template_id
    @body = template.render([@user]) {|content|
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
      filename = email["invitation_fields"]["calendar_invite_filename"] || 'invite'
      cal = calendar_invite(email)
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

  def calendar_invite email
    require 'icalendar'
    require 'icalendar/tzinfo'
    cal = Icalendar::Calendar.new

    begin
      utc_offset = ActiveSupport::TimeZone[email.timezone].now.formatted_offset
      timezone = ActiveSupport::TimeZone[email.timezone].tzinfo.canonical_zone
      ical_timezone = timezone.ical_timezone email.calendar_invite_start.localtime(utc_offset)
      cal.add_timezone ical_timezone
    rescue => exception
      puts exception
    end

    cal.prodid = '-//Acme Widgets, Inc.//NONSGML ExportToCalendar//EN'
    cal.version = '2.0'

    description = nil
    organizer   = 'support@eventkaddy.com'


    if !email["invitation_fields"].blank?
      if email["invitation_fields"]["calendar_invite_desciption"].present?
        description = ActionController::Base.helpers.strip_tags(email["invitation_fields"]["calendar_invite_desciption"])
      end

      if email["invitation_fields"]["calendar_invite_organizer"].present?
        organizer   = email["invitation_fields"]["calendar_invite_organizer"]
      end
    end

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(email.calendar_invite_start.localtime(utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.dtend       = Icalendar::Values::DateTime.new(email.calendar_invite_end.localtime(utc_offset), 'tzid' => ical_timezone.tzid.to_s)
      e.summary     = email.organization.name
      e.organizer   = organizer
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
