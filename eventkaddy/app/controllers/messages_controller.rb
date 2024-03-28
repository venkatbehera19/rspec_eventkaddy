class MessagesController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource


  def display_message

    if (current_user!=nil) then

      if (current_user.role? :super_admin) then

        @events = Event.select('*')

        respond_to do |format|
          format.html {render :layout => 'subevent_2013'}
        end

      elsif (current_user.role? :client) then

        @events = Event.joins('
        LEFT OUTER JOIN users_events ON users_events.event_id=events.id').where("users_events.user_id = ?",current_user.id)

          respond_to do |format|
            format.html {render :layout => 'subevent_2013'}
          end

      elsif (current_user.role? :speaker) then

	      @speaker = get_speaker

	      #determine number of remaining requirements yet to be filled
	      @requirements = Requirement.joins(:requirement_type).where(event_id:session[:event_id],required:true).where(requirement_types: { requirement_for: 'speaker' })
	      @requirements.each do |requirement|
        attribute=@speaker.read_attribute(requirement.requirement_type.name)

        if !(attribute.nil? || attribute=="")
          @requirements = @requirements.reject {|n| n==requirement}
        end

      end

	      #retrieve existing pdfs
        @event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
        @pdf_files       = EventFile.where(event_id:@speaker.event_id,event_file_type_id:@event_file_type.id)

        @event_setting   = EventSetting.where("event_id= ?",session[:event_id]).first
        @tab_type_ids    = []

	      TabType.where(portal:"speaker").each do |t|
	        @tab_type_ids.push(t.id)
	      end

	      @tabs = Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_ids)

        @events = Event.joins('
        LEFT OUTER JOIN users_events ON users_events.event_id=events.id').where("users_events.user_id = ?",current_user.id)

        respond_to do |format|
          format.html {render :layout => 'speakerportal_2013'}
            #format.html { redirect_to("/speaker_portals/checklist") }
        end

      elsif (current_user.role? :exhibitor) then

        @events = Event.joins('
        LEFT OUTER JOIN users_events ON users_events.event_id=events.id').where("users_events.user_id = ?",current_user.id)

        respond_to do |format|
          format.html {render :layout => 'exhibitorportal'}
            #format.html { redirect_to("/speaker_portals/checklist") }
          end
      end

    else

      respond_to do |format|
          #format.html { render :index, :layout => 'splashpage_2013'  }
          format.html { redirect_to("/users/sign_in") } #special redirect for wvc 2014 speaker portal
          end

    end#role
  end#display message

#   def show
#     @message = Message.find(params[:id])
#
#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @message }
#     end
#   end

  def new
    @message = Message.new

    @event       = Event.find(session[:event_id])
    @type_id     = EventFileType.where(name:"event_message_image").first.id
    @event_files = EventFile.where(event_id:session[:event_id], event_file_type_id:@type_id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message }
    end
  end

  def edit
    @message     = Message.find(params[:id])
    @event       = Event.find(session[:event_id])
    @type_id     = EventFileType.where(name:"event_message_image").first.id
    @event_files = EventFile.where(event_id:session[:event_id], event_file_type_id:@type_id)

  end

  def create

    if (params[:event_file]!='' || nil) then
        @event_file          = EventFile.new
        @event_file.event_id = session[:event_id]
        @event_file.updatePhoto(params)

    respond_to do |format|
      if @event_file.save
        format.html { redirect_to('/event_settings/show_messages', :notice => 'Message was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
      end
    end

    else

    @message          = Message.new(message_params)
    @message.event_id = session[:event_id]
    @event            = Event.find(session[:event_id])

    respond_to do |format|
      if @message.save

        format.html { redirect_to('/event_settings/show_messages', :notice => 'Message was successfully created.') }
        format.xml  { render :xml => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end
  end

  def update

    if (params[:event_file]!='' || nil) then
        @event_file          = EventFile.new
        @event_file.event_id = session[:event_id]
        @event_file.updatePhoto(params)

      respond_to do |format|
        if @event_file.save
          format.html { redirect_to('/event_settings/show_messages', :notice => 'Message was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @event_file.errors, :status => :unprocessable_entity }
        end
      end

    else

      @message = Message.find(params[:id])

      @message.title        = params[:message][:title]
      @message.content      = params[:message][:content]
      @message.message_type = params[:message][:message_type]

  		@event = Event.find(session[:event_id])


      respond_to do |format|
        if @message.save

          format.html { redirect_to('/event_settings/show_messages', :notice => 'Message was successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to('/event_settings/show_messages') }
      format.xml  { head :ok }
    end
  end

  def ajax_data
    @type = EventFileType.where(name:"event_message_image").first.id
    render :plain => EventFile.where(event_id:session[:event_id],event_file_type_id:@type).last.path
  end



  def subscribe
      @speaker              = Speaker.where(token:params[:token]).first
      @speaker.unsubscribed = false
      @speaker.save
  end

  def unsubscribe
    @token = params[:token]
    if Speaker.where(token:@token).length>0
      @speaker              = Speaker.where(token:@token).first
      @speaker.unsubscribed = true
      @speaker.save
    end
    if Exhibitor.where(token:@token).length>0
      @exhibitor              = Exhibitor.where(token:@token).first
      @exhibitor.unsubscribed = true
      @exhibitor.save
	end
	respond_to do |format|
		format.html { render :layout => false  }
	end
  end

  private

  def get_speaker
    user = User.find(current_user.id)
    return Speaker.where(email:user.email,event_id:session[:event_id]).first
  end

  def message_params
    params.require(:message).permit(:event_id, :title, :content, :local_time, :active_time, :status, :mail, :message_type)
  end

end