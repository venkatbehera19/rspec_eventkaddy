require 'omniauth'
require "google/api_client/client_secrets.rb"
require "google/apis/calendar_v3"
require 'icalendar'
require 'icalendar/tzinfo'
class EventRegistrationsController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action { set_ga_key('simple_registration') }
  layout 'simple_registration'

  def new
    @attendee = Attendee.new(event_id: params[:event_id])
    @simple_registration_settings = Setting.return_simple_registration_settings(params[:event_id])
    @attendees_count = Attendee.where(event_id:params[:event_id]).count
  end

  def create
    @attendee = Attendee.where(event_id: params[:event_id], email: params[:attendee][:email]).first
    @simple_registration_settings = Setting.return_simple_registration_settings(params[:event_id])

    if !@attendee.blank?
      if @simple_registration_settings.registration_with_email_confirmation && !@attendee.confirmed?
        flash[:notice] = "Please verify your email address to complete the registration process."
      else
        flash[:alert] = "Email address already registered"
      end
      redirect_to "/#{params[:event_id]}/event_registrations/new" and return
    end

    @attendee = Attendee.new attendee_params
    @simple_registration_settings.registration_with_email_confirmation && @attendee.generate_confirmation_token

    if @attendee.save
      @attendee.send_password_mail_simple_reg if @simple_registration_settings.send_attendee_password
      if @simple_registration_settings.registration_with_email_confirmation
        AttendeeMailer.registration_confirmation(params[:event_id], @attendee).deliver_now
        redirect_to "/#{params[:event_id]}/event_registrations", :notice => "A confirmation instruction has been sent to your email address. Please verify it to continue."
      else
        @simple_registration_settings.send_calendar_invite && CalendarInviteMailer.invite(params[:event_id],@attendee).deliver_now
        redirect_to  "/#{params[:event_id]}/event_registrations/show/#{@attendee.slug}"
      end
    else
      @attendees_count = Attendee.where(event_id:params[:event_id]).count
      render action: 'new'
    end
  end

  def show
    @attendee = Attendee.find_by_slug(params[:slug])
    @attendee.blank? && (redirect_to "/#{params[:event_id]}/event_registrations/new" and return)
    @settings = Setting.return_simple_registration_settings(params[:event_id])
  end

  def confirm
    @attendee = Attendee.find_by_confirmation_token(params[:token])
    if @attendee.blank? || @attendee.slug != params[:user]
      @message="Invalid link or link has expired"
    else
      @message="Email address verified successfully!"
      @simple_registration_settings = Setting.return_simple_registration_settings(params[:event_id])
      @simple_registration_settings.send_calendar_invite && CalendarInviteMailer.invite(params[:event_id],@attendee).deliver_now
      redirect_to  "/#{params[:event_id]}/event_registrations/show/#{@attendee.slug}", notice: @message
    end
  end


  def google_calendar_callback
    if request.env['omniauth.auth'] && !request.env['omniauth.auth']['credentials'].blank?

      service = get_google_calendar_client request.env['omniauth.auth']['credentials']
      @event = Event.find request.env['omniauth.params']['event_id']
      calendar_event = Google::Apis::CalendarV3::Event.new(
        summary: @event.name,
        description: JSON.parse(@event.calendar_json)['event_description'].html_safe,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time:  @event.event_start_at.localtime(@event.utc_offset).to_datetime.rfc3339
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @event.event_end_at.localtime(@event.utc_offset).to_datetime.rfc3339
        ),
        reminders: Google::Apis::CalendarV3::Event::Reminders.new(
          use_default: false,
          overrides: [
            Google::Apis::CalendarV3::EventReminder.new(
              reminder_method: 'email',
              minutes: 24 * 60
            ),
            Google::Apis::CalendarV3::EventReminder.new(
              reminder_method: 'popup',
              minutes: 30
            )
          ]
        )
      )
      result = service.insert_event('primary', calendar_event)
      puts "Event created: #{result.html_link}"
      redirect_to "/#{@event.id}/event_registrations/show/#{request.env['omniauth.params']['slug']}", notice: "Event successfully added to your google calendar! <a href='#{result.html_link}' target='_blank'>Click here</a> to check.".html_safe
    else
      redirect_to "/#{@event.id}/event_registrations/show/#{request.env['omniauth.params']['slug']}", alert: "Permission Denied."
    end
  end

  def get_google_calendar_client omniauth_credentials
    service = Google::Apis::CalendarV3::CalendarService.new
    secrets = Google::APIClient::ClientSecrets.new({
      "web" => {
        "access_token" => omniauth_credentials['token'],
        "refresh_token" => omniauth_credentials['refresh_token'],
        "client_id" => ENV["GOOGLE_API_KEY"],
        "client_secret" => ENV["GOOGLE_API_SECRET"]
      }
    })
    service.authorization = secrets.to_authorization
    return service
  end

  def icalendar
    @event = Event.find params[:event_id]
    cal = Icalendar::Calendar.new

    begin
      timezone = ActiveSupport::TimeZone[@event.timezone].tzinfo.canonical_zone
      ical_timezone = timezone.ical_timezone @event.event_start_at.localtime(@event.utc_offset)
      cal.add_timezone ical_timezone
    rescue => exception
      puts exception
    end

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
      e.alarm do |a|
        a.summary = "Alarm notification"
        a.trigger = "-P1DT0H0M0S" # 1 day before
      end
    end

    if params[:format] == 'vcs'
      cal.prodid = '-//Microsoft Corporation//Outlook MIMEDIR//EN'
      cal.version = '1.0'
      filename += '.vcs'
    else # ical
      cal.prodid = '-//Acme Widgets, Inc.//NONSGML ExportToCalendar//EN'
      cal.version = '2.0'
      filename += '.ics'
    end
    
    cal.publish
    send_data cal.to_ical, type: 'text/calendar', disposition: 'attachment', filename: filename
  end

  def oauth_failure
    redirect_to "/#{request.env['omniauth.params']['event_id']}/event_registrations/show/#{request.env['omniauth.params']['slug']}", alert: "Permission Denied."
  end
  
  private

  def attendee_params
    params.require(:attendee).permit(:first_name, :last_name, :email, :title, :company).merge(event_id: params[:event_id])
  end
end
