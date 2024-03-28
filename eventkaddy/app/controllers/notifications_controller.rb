class NotificationsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource

  def hidden_notification
    @types        = HiddenNotificationType.pluck(:name)
    @notification = Notification.new
  end

  def create_hidden_notification
    Notification.create_hidden_notification params[:type_name], session[:event_id]
    redirect_to "/notifications/hidden_notification",
                notice: "#{params[:type_name]} notification created."
  end

  # def mobile_data

  #   if (params[:event_id]) then
  #     @notifications = Notification.select('notifications.*, DATE_FORMAT(created_at,\'%Y-%M-%D %H:%i:%s\') AS created_at_formatted, DATE_FORMAT(notifications.localtime,\'%M %D, %l:%i %p\') AS display_date').where("event_id= ?",params[:event_id]).order('created_at ASC')

  #     render :json => @notifications.to_json, :callback => params[:callback]

  #   end

  # end

  #create the special notification
  def send_data_update

    #remove existing data_update notifications, if any
    delete_result = Notification.where('event_id=? AND name=?',session[:event_id],'New Data').destroy_all

    #add the new one
		@notification= Notification.new
		@notification.event_id = session[:event_id]
		@notification.name = 'New Data'
		@notification.description = 'New Data'

		#set the timezone, particular to each event
		@event = Event.find(session[:event_id])
		ua_app_key = @event.notification_app_key
		ua_app_master_secret = @event.notification_app_master_secret

#		t_offset = @event.utc_offset
#		if (t_offset==nil) then
#			t_offset = "+00:00" #default to UTC 0
#		end
#		t = Time.now

#		localtime = t.localtime(t_offset).strftime('%Y-%m-%d %H:%M:%S')
		#Rails::logger.debug "localtime: #{localtime}"
#		@notification.localtime = localtime

		@notification.futureSendCheck(@event)
		@notification.setLocalTime(@event)

		#if (@notification.status=="active") then
		#	@notification.sendUAPush(ua_app_key,ua_app_master_secret)
		#end

		@notification.save

    respond_to do |format|
      format.html { redirect_to("/notifications", :notice => 'Data Update Notification was successfully added.') }
    end


  end

  # The below two methods will have to be refactored after ahvma, but for
  # now I am making them as close to possible as the original data push
  # notification method. There is a fair amount of redundant code though,
  # and I would prefer this all be handled by one form

  #create the special notification
  # (Basically this just makes a notification active so that it doesn't
  # get picked up by the cron task, with the exact name required)
  def send_ce_credits_on

    Notification.where('event_id=? AND name=?',session[:event_id],'EK_TOGGLE_ON_CE_CREDITS').destroy_all

    @notification             = Notification.new
    @notification.event_id    = session[:event_id]
    @notification.name        = 'EK_TOGGLE_ON_CE_CREDITS'
    @notification.description = 'EK_TOGGLE_ON_CE_CREDITS'

    @event               = Event.find(session[:event_id])
    ua_app_key           = @event.notification_app_key
    ua_app_master_secret = @event.notification_app_master_secret

    @notification.futureSendCheck(@event)
    @notification.setLocalTime(@event)

    @notification.save

    respond_to do |format|
      format.html { redirect_to("/notifications", :notice => 'CE Credits On Update Notification was successfully added.') }
    end
  end

  #create the special notification
  # (Basically this just makes a notification active so that it doesn't
  # get picked up by the cron task, with the exact name required)
  def send_ce_credits_off

    Notification.where('event_id=? AND name=?',session[:event_id],'EK_TOGGLE_OFF_CE_CREDITS').destroy_all

    @notification             = Notification.new
    @notification.event_id    = session[:event_id]
    @notification.name        = 'EK_TOGGLE_OFF_CE_CREDITS'
    @notification.description = 'EK_TOGGLE_OFF_CE_CREDITS'

    @event               = Event.find(session[:event_id])
    ua_app_key           = @event.notification_app_key
    ua_app_master_secret = @event.notification_app_master_secret

    @notification.futureSendCheck(@event)
    @notification.setLocalTime(@event)

    @notification.save

    respond_to do |format|
      format.html { redirect_to("/notifications", :notice => 'CE Credits Off Update Notification was successfully added.') }
    end
  end

  def index
    @notifications = Notification.where(event_id: session[:event_id]).order(:active_time)
    @event         = Event.find session[:event_id]
    @event_timezone = ActiveSupport::TimeZone.all.find { |tz| tz.now.formatted_offset.eql? @event.utc_offset }
  
    @active_dates = @notifications.select('DATE(notifications.active_time) as dt')
      .map { |n| n.dt}.uniq
    render :layout => mobile ? 'cms_mobile' : 'subevent_2013'
  end

  def show
    @notification = Notification.find(params[:id])

    respond_to do |format|
      format.html {
        render :layout => mobile ? 'cms_mobile' : 'subevent_2013'
      }
      format.xml  { render :xml => @notification }
    end
  end

  def new
    @notification = Notification.new
    @event        = Event.find(session[:event_id])
    t             = Time.now
    @localtime    = t.localtime(@event.utc_offset)
    @site_time    = @localtime # see edit method; @localtime really means active_time for the form
    @sessions = Session.select('session_code, title').where(event_id: session[:event_id]).order(:session_code)

    respond_to do |format|
      format.html {
        render :layout => mobile ? 'cms_mobile' : 'subevent_2013'
      }
      format.xml  { render :xml => @notification }
    end
  end

  def edit
    @notification = Notification.find(params[:id])
    @event        = Event.find(session[:event_id])
    @sessions = Session.select('session_code, title').where(event_id: session[:event_id]).order(:session_code)

    #year=@notification.active_time.strftime('%Y').to_i
    #month=@notification.active_time.strftime('%m').to_i
    #day=@notification.active_time.strftime('%d').to_i
    #hour=@notification.active_time.strftime('%H').to_i
    #minute=@notification.active_time.strftime('%M').to_i
    #second=@notification.active_time.strftime('%S').to_i
    #t = Time.new(year,month,day,hour,minute,second, '+00:00')

    t                         = Time.parse("#{@notification.active_time.strftime('%Y-%m-%d %H:%M:%S')}Z")
		@localtime                = t.localtime(@event.utc_offset)
    @notification.active_time = @localtime
    @site_time                = Time.now.localtime(@event.utc_offset)
    render :layout => mobile ? 'cms_mobile' : 'subevent_2013'
  end

  def create
    params[:notification][:pn_filters] = params[:pn_filters] && params[:pn_filters].length > 0 ? params[:pn_filters].to_s : nil
    params[:notification][:session_codes] = params[:session_codes] && params[:session_codes].length > 0 ? params[:session_codes] : []
    @notification = Notification.new(notification_params)
		@notification.event_id= session[:event_id]
		@notification.unpublished = params[:notification][:unpublished]
		#iOS urbanairship push notification
		@event = Event.find(session[:event_id])

		#handle future send (active) time if set
		@notification.futureSendCheck(@event)
		@notification.setLocalTime(@event)

    respond_to do |format|
      if @notification.save

        # this must happen after, or our validation and update
        # to single quotes wont happen

        #Actions below will be performed by cron job
        if @notification.status=="active" && !@notification.unpublished? && !@notification.on_home_feed_announcement
          unless @notification.has_session_codes?
            @notification.sendUAPushV2 if @notification.push_notification?
          else # they will be caught by the crontask running UAV4
            puts "notification has session_codes; generating attendees_notifications"
            puts @notification.create_attendees_notifications_for_iattend_session.inspect
          end
        end


        format.html {
          redirect_to(
            "/notifications/#{@notification.id}?mobile=#{mobile}",
            :notice => 'Notification was successfully created.'
          )
        }
        format.xml  { render :xml => @notification, :status => :created, :location => @notification }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    pn_filters = params[:pn_filters] && params[:pn_filters].length > 0 ? params[:pn_filters].to_s : nil
    session_codes = params[:session_codes] && params[:session_codes].length > 0 ? params[:session_codes] : []
    @notification = Notification.find(params[:id])
    @sessions = Session.select('session_code, title').where(event_id: session[:event_id]).order(:session_code)
		@notification.name = params[:notification][:name]
		@notification.description = params[:notification][:description]
		@notification.unpublished = params[:notification][:unpublished]
    @notification.push_notification = params[:notification][:push_notification]
    @notification.pn_filters = pn_filters
    @notification.session_codes = session_codes
    @notification.web_url = params[:notification][:web_url]
    @notification.on_home_feed_announcement = params[:notification][:on_home_feed_announcement]

		year=params[:notification]["active_time(1i)"].to_i
    month=params[:notification]["active_time(2i)"]
    day=params[:notification]["active_time(3i)"].to_i
    hour=params[:notification]["active_time(4i)"].to_i
    minute=params[:notification]["active_time(5i)"].to_i
    second=0

		@notification.active_time = Time.new(year,month,day,hour,minute,second, '+00:00')

		#iOS urbanairship push notification
		@event = Event.find(session[:event_id])

		#handle future send (active) time if set
		@notification.futureSendCheck(@event)
		@notification.setLocalTime(@event)


    respond_to do |format|
      if @notification.save #update!(notification_params)

        # this must happen after save, or validation wont occur
        
        #Actions below will be performed by cron job
        if @notification.status=="active" && !@notification.unpublished? && !@notification.on_home_feed_announcement
          unless @notification.has_session_codes?
            @notification.sendUAPushV2 if @notification.push_notification?
          else # they will be caught by the crontask running UAV4
            puts "notification has session_codes; generating attendees_notifications"
            puts @notification.create_attendees_notifications_for_iattend_session.inspect
          end
        end

        format.html {
          redirect_to(
            "/notifications/#{@notification.id}?mobile=#{mobile}",
            :notice => 'Notification was successfully updated.'
          )
        }
        format.xml  { head :ok }
      else
        format.html {
          render :action => "edit"
        }
        format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to("/notifications/?mobile=#{mobile}") }
      format.xml  { head :ok }
    end
  end

  private

  def mobile
    @mobile = params[:mobile] == "true"
    @mobile
  end

  def notification_params
    params.require(:notification).permit(:event_id, :name, :description, :localtime, :active_time, :status, :curl_result, :pn_filters, :hidden_notification_type_id, :session_codes, :unpublished, :push_notification, :web_url, :on_home_feed_announcement)
  end

end