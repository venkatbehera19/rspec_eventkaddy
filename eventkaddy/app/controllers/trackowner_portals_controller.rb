

# this never ended up being used; I think it was originally designed for
# WVC to have less powerful users manage data. The code here is not useless,
# it was based off the the speaker portal in some ways. Mostly it is a CMS
# but with a modifier to only show and manipulate a subset of sessions. It is
# not abstracted very well and has its fingers in a few reports, which I am
# going to remove as it make the code harder to read.

class TrackownerPortalsController < ApplicationController
  layout 'trackownerportal'

  def landing
  	@user = User.find(current_user.id)
    @event_setting   = EventSetting.where("event_id= ?",session[:event_id]).first
    session[:layout] = 'trackownerportal'

  end

  def sessions
    #@sessions = Session.all
    if (session[:event_id]) then

      @event_id      = session[:event_id]
      @event_setting = EventSetting.where(event_id:@event_id).first

      #disabled while using server-side fetch for datatables
      #@sessions = Session.select("DISTINCT sessions.*,location_mappings.name, CONCAT_WS(' ', DATE_FORMAT(sessions.date, '%Y-%m-%d'),' | ',DATE_FORMAT(sessions.start_at, '%H:%i')) AS session_date").joins('LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id').where("sessions.event_id= ?",session[:event_id]).order('session_code ASC')

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => @sessions }
          #format.json { render :json => @sessions.to_json, :callback => params[:callback] }
          format.json { render json: SessionsDatatable.new(view_context,@event_id, current_user) }
        end

    else
      redirect_to "/home/session_error"
    end

  end

  def speakers

  if (session[:event_id]) then

    @event_id = session[:event_id]

    #disabled while using server-side fetch for datatables
    #@speakers = Speaker.select('DISTINCT speakers.*').where("event_id= ?",session[:event_id])

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @speakers }
        #format.json { render :json => @speakers.to_json, :callback => params[:callback] }
        format.json { render json: SpeakersDatatable.new(view_context,@event_id, current_user) }
      end

    else
      redirect_to "/home/session_error"
    end

  end

  def speaker_files_zip
    @trackowner = get_trackowner

    filename = @trackowner.email+'_speaker_files.zip'
    path = Rails.root.join( 'download','event_data',session[:event_id].to_s,'speaker_files', filename )

    @trackowner.bundleSpeakerFiles

    if File.exists?(path) && (current_user.role? :trackowner)
      send_file( path, x_sendfile: true )
    else
      raise ActionController::RoutingError, "File not available."
    end
  end

  def session_files_zip
    @trackowner = get_trackowner
    @trackowner.bundleSessionFiles

    filename = @trackowner.email+'_session_files.zip'
    path = Rails.root.join( 'public','event_data',session[:event_id].to_s,'session_files', filename )


    if File.exists?(path) && (current_user.role? :trackowner)
      send_file( path, x_sendfile: true )
    else
      raise ActionController::RoutingError, "File not available."
    end
  end

  def session_files
    if (session[:event_id]) then

      @event_id     = session[:event_id]
      @current_user = current_user

      if params[:type]
        @session_file_type_id = SessionFileType.where(name:params[:type]).first.id
      else
        @session_file_type_id =[1,2]
      end
      #disabled while using server-side fetch for datatables
      # @session_files = SessionFile.joins('JOIN sessions ON sessions.id=session_files.session_id').where(event_id:session[:event_id],session_file_type_id:@session_file_type.id)#.limit(100)

      #backbone data
      # @speakers = Speaker.select('first_name,last_name,honor_prefix,honor_suffix,email,sessions.id AS session_id, speakers.id AS speaker_id').joins('
      #   JOIN sessions_speakers ON speakers.id=sessions_speakers.speaker_id
      #   JOIN sessions ON sessions_speakers.session_id=sessions.id
      #   ').where(event_id:session[:event_id])

      respond_to do |format|
        format.html # index.html.erb
        #format.xml {render :xml => @session_file_type}
        format.xml {render :xml => @session_files}
        format.xml {render :xml => @speakers}
        format.json { render json: SessionFilesDatatable.new(view_context,@event_id,@current_user,@session_file_type_id)}
      end

    else
      redirect_to "/home/session_error"
    end
  end


  #show change password page
  def edit_account
    @user = User.find(current_user.id)

  end

  #PUT
  #update password
  def update_account

    @user = User.find(current_user.id)

    if params[:user][:password].blank?
      [:password,:password_confirmation,:current_password].collect{|p| params[:user].delete(p) }
    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:user][:current_password])
    end

    respond_to do |format|
      if @user.errors[:base].empty? and @user.update!(params.require(:user).permit(:password, :password_confirmation))
        flash[:notice] = "Your account has been updated"
        sign_in(@user, bypass:true)
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { render :action => :landing }
      else
        format.json { render :text => "Could not update user", :status => :unprocessable_entity } #placeholder
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.html { render :action => :edit_account, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml, :html)


  end

  # def show_message
  #   @exhibitor = Exhibitor.find(current_user.exhibitors.first)
  #   @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
  # end

  # def messages
  #   @event         = Event.where(id:session[:event_id]).first
  #   @event_setting = EventSetting.where(event_id:@event.id).first
  #   @messages      = Message.where(event_id:@event.id,status:"active",message_type:[2,3])
  #   # @current_tab = get_current_tab("Messages")

  # end

  private

    def get_trackowner
      # user = User.find(current_user.id)
      # return Trackowner.where(email:user.email,event_id:session[:event_id]).first
      if current_user.role? :trackowner
        current_user.first_or_create_trackowner(session[:event_id])
      end
    end

    # def get_current_tab(default_name)
    #   current_tab = Tab.select('tabs.*,tab_types.default_name').joins('
    #   JOIN tab_types ON tabs.tab_type_id=tab_types.id').where('event_id=? AND default_name=?',session[:event_id],default_name).first

    #   return current_tab
    # end

end
