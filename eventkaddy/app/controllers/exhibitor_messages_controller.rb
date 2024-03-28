class ExhibitorMessagesController < ApplicationController
  layout :set_layout

  helper_method :is_thread_unread?
  before_action :set_exhibitor_attendee, only: [:messages, :new, :create, :reply, :markread, :settings]
  # before_action :check_if_exhibitor
  include ExhibitorPortalsHelper

  def messages
    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    # end
    @exhibitor_attendee.blank? && (redirect_to :action => 'inaccessible' and return)
    @exhibitor && !check_for_payment && (redirect_to '/exhibitor_portals/complete_purchase' and return)

    @title = "<span class='glyphicon glyphicon-envelope'></span> Messages".html_safe
    @message_threads = AppMessageThread
    .joins("INNER JOIN attendees_app_message_threads ON app_message_threads.id = attendees_app_message_threads.app_message_thread_id")
    .where("attendees_app_message_threads.attendee_id = #{@exhibitor_attendee.attendee_id}")
    .order(:updated_at)
    @current_tab = get_current_tab("Conference Messages")
    # find(session[:attendee_id]).app_message_threads.order('updated_at')
    # SELECT `app_message_threads`.* FROM `app_message_threads` INNER JOIN `attendees_app_message_threads` ON `app_message_threads`.`id` = `attendees_app_message_threads`.`app_message_thread_id` WHERE `attendees_app_message_threads`.`attendee_id` = 1002824  ORDER BY updated_at
  end

  def new
    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    # end

    @exhibitor_attendee.blank? && (redirect_to :action => 'inaccessible' and return)

    @title = "<span class='glyphicon glyphicon-envelope'></span> Messages".html_safe
    @message = AppMessage.new

    @attendees = Attendee.select('id, first_name, last_name').where('event_id=? AND id!=?',session[:event_id], @exhibitor_attendee.attendee_id).order('first_name')
  end

  def create

    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    #   sender = Attendee.find @exhibitor_attendee.attendee_id
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    #   sender = exhibitor_staff
    # end
    @exhibitor_attendee.blank? && (redirect_to :action => 'inaccessible' and return)
    sender = @exhibitor_staff.blank? ? Attendee.find(@exhibitor_attendee.attendee_id) : @exhibitor_staff

        #get attendee account codes from exhibitor
    @group_attendees = params[:recipient_attendees].split(',')
    @arrayToSubtract = Array.new
    @group_attendees_array = Array.new
    @recipients_array = Array.new
    @group_attendees.each do |g| #id still starts with e_, a_, t_
      if g[0] == 'e' #exhibitor
        @group_attendees_array = BoothOwner.where(exhibitor_id:g[2..-1]).pluck(:attendee_id)
        @group_attendees.delete(g.to_s)
      elsif g[0] == 'a' #attendee group

      elsif g[0] == 't' #attendee tag group

      end
    end

    @group_attendees.each do |x|
      puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"+x
      if x.starts_with? "a_"
        x = x[2..-1]
      end
      @attendee = Attendee.where(event_id:session[:event_id], account_code:x).first
      @group_attendees_array.push(@attendee.id)
      @attendee.id != @exhibitor_attendee.attendee_id && @recipients_array.push(@attendee)
    end


    @group_attendees_array = @group_attendees_array - [@exhibitor_attendee.attendee_id] #if you are sending a message to yourself this will cause an error that no recipient was selected
    @group_attendees_array.push(@exhibitor_attendee.attendee_id)
#    @group_attendees_array.each do |p|
#      puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>P is ----:" + p.to_s
#    end

    @group_attendees_array = @group_attendees_array.uniq

    if @group_attendees_array.length>1 && app_message_thread = AppMessageThread.create(event_id:session[:event_id], title:params[:thread_title], active:true)

      if app_message = AppMessage.create(event_id:session[:event_id], app_message_thread_id:app_message_thread.id, attendee_id:@exhibitor_attendee.attendee_id, content:params[:message], msg_time:get_msg_time)

        if AttendeesAppMessageThread.add_recipients(@group_attendees_array,app_message_thread.id,@exhibitor_attendee.attendee_id)
          @recipients_array.each do |recipient_attendee|
            recipient_attendee.notify_message_via_email && AttendeeMailer.email_new_message_notification(session[:event_id], recipient_attendee, sender, params[:thread_title], params[:message]).deliver
          end
          redirect_to '/exhibitor_portals/messages', notice:'Successfully created new thread.'
        end
      end
    else
      redirect_to '/exhibitor_messages/new', alert:'Failed to create new thread. Please select at least one recipient.'
    end
  end

  def reply

    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    #   sender = Attendee.find @exhibitor_attendee.attendee_id
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    #   sender = exhibitor_staff
    # end
    @exhibitor_attendee.blank? && (redirect_to :action => 'inaccessible' and return)
    sender = @exhibitor_staff.blank? ? Attendee.find(@exhibitor_attendee.attendee_id) : @exhibitor_staff

    @result                   = {}
    @result["reply"]          = {}
    @result["status"]         = false
    @result["error_messages"] = []

    msg_time = get_msg_time

    if AppMessage.create(event_id:session[:event_id], app_message_thread_id:params[:thread_id], attendee_id:@exhibitor_attendee.attendee_id, content:params[:reply], msg_time:msg_time)
      @result["status"] = true
      @result["message"] = {'author' => Attendee.find(@exhibitor_attendee.attendee_id).full_name, 'thread_id' => params[:thread_id], 'msg_time' => msg_time, 'content' => params[:reply]}
      @attendee_app_message_thread = AttendeesAppMessageThread.where(app_message_thread_id:params[:thread_id])
      @attendee_app_message_thread.each do |a|
        if a.read_status && a.attendee_id!=@exhibitor_attendee.attendee_id
          a.read_status = false
        elsif a.attendee_id==@exhibitor_attendee.attendee_id
          a.read_status = true
        end
        a.save!
      end
      # Send email to each recipient of the thread
      email_recipients = AttendeesAppMessageThread.select(:attendee_id).where(app_message_thread_id: params[:thread_id])
      msg_thread = AppMessageThread.find params[:thread_id]
      email_recipients.each do |email_recipient|
        if(email_recipient.attendee_id != @exhibitor_attendee.attendee_id)
          recipient_attendee = Attendee.find(email_recipient.attendee_id)
          recipient_attendee.notify_message_via_email && AttendeeMailer.email_new_message_notification(session[:event_id], recipient_attendee, sender, msg_thread.title, params[:reply]).deliver
        end
      end

    else
      @result["status"] = false
      @result["error_messages"] << 'A problem occured while trying to send your message.'
    end
    render :json => @result.to_json
  end

  def ajax_attendees_array

    filter_on_id = false
    attendee_id = ''
    if params[:id]
      filter_on_id = true
      attendee_id = sanitize_search(params[:id])
    end
    Rails.cache.fetch "ajax-attendees-cache#{session[:event_id]}}", force: true do
      auto_complete_data = []
      where = ""
      if filter_on_id
        where = ' and id='+attendee_id
      end
      Attendee.where("event_id="+(session[:event_id].to_s) + where).each {|a| auto_complete_data << {value:a.account_code, label:a.full_name, id:a.id} }
      auto_complete_data
    end

    auto_complete_data = Rails.cache.read "ajax-attendees-cache#{session[:event_id]}}"

    render :json => auto_complete_data
  end

  def markread

    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    # end
    @exhibitor_attendee.blank? && (redirect_to :action => 'inaccessible' and return)
    msg_time = get_msg_time

    @attendee_app_message_thread = AttendeesAppMessageThread.where(app_message_thread_id:params[:id], attendee_id:@exhibitor_attendee.attendee_id)
    if(@attendee_app_message_thread[0])
      @attendee_app_message_thread[0].read_status = true
      @attendee_app_message_thread[0].save!
      render :plain => "true"
      return
    end

    render :plain => "false"
  end

  def is_thread_unread?(thread_id)
    @attendee_app_message_thread = AttendeesAppMessageThread.where(app_message_thread_id:thread_id, attendee_id:@exhibitor_attendee.attendee_id).first
    if @attendee_app_message_thread && @attendee_app_message_thread.read_status
      return false
    end
    return true
  end

  def inaccessible
  end

  def settings
    # exhibitor_staff = ExhibitorStaff.find_by_user_id current_user.id
    # if exhibitor_staff.blank?
    #   @exhibitor = get_exhibitor
    #   (@exhibitor.blank?) && (redirect_to :action => 'inaccessible' and return)
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(@exhibitor.id)
    # else
    #   @exhibitor_attendee = BoothOwner.find_by_exhibitor_id(exhibitor_staff.exhibitor_id)
    # end
    @attendee = Attendee.find @exhibitor_attendee.attendee_id
  end

  def settings_update
    @attendee =  Attendee.find params[:attendee_id]
    @attendee.update!(attendee_params)
    respond_to do |format|
      if @attendee.update!(attendee_params)
        format.html { redirect_to '/exhibitor_portals/messages', notice:'Successfully updated message settings.' }
        format.json { head :ok }
      else
        format.html { render action: "settings" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_exhibitor_attendee
    @exhibitor_staff = ExhibitorStaff.where(event_id: session[:event_id], user_id: current_user.id).first
    if @exhibitor_staff.blank?
      @exhibitor = get_exhibitor
    else
      @exhibitor = @exhibitor_staff.exhibitor
    end
    @exhibitor_attendee = nil
    if !@exhibitor || @exhibitor.company_name.blank?
      @exhibitor_attendee = nil
    else
      @exhibitor_attendee = BoothOwner.joins(:attendee).where("booth_owners.exhibitor_id = ? or attendees.company = ?", @exhibitor.id, @exhibitor.company_name).first
    end
  end

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def get_exhibitor
    if current_user.role? :exhibitor then
      current_user.first_or_create_exhibitor( session[:event_id] )
    else
      puts "test: #{session[:exhibitor_id_portal]}"
      Exhibitor.find(session[:exhibitor_id_portal])
    end
  end

  def get_msg_time
    time = Time.now
    time.strftime("%b #{time.day.ordinalize}, %r")
  end

  def attendee_params
    params.require(:attendee).permit(:notify_message_via_email)
  end

  def get_current_tab(default_name)
    current_tab = Tab.tab_by_event_and_default_name session[:event_id], default_name, 'exhibitor'
  end

end
