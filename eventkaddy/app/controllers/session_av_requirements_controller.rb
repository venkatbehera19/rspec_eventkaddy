class SessionAvRequirementsController < ApplicationController
  layout :set_layout

  before_action :set_layout_variables #before_action in rails 4

  def set_layout_variables
    if set_layout === 'speakerportal_2013'
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
      @pdf_files = EventFile.where(event_id:@speaker.event_id,event_file_type_id:@event_file_type.id)

      @event_setting = EventSetting.where("event_id= ?",session[:event_id]).first
      @tab_type_ids = Array.new
      TabType.where(portal:"speaker").each do |t|
        @tab_type_ids.push(t.id)
      end

      @tabs = Tab.where(event_id:session[:event_id],tab_type_id:@tab_type_ids)
    end

  end

  def index

    @session = Session.find(params[:session_id])
    @event_setting = EventSetting.where(event_id:session[:event_id]).first

    @session_av_requirements = SessionAvRequirement.where(session_id:@session.id)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @session_av_requirement = SessionAvRequirement.new

    @session_id = params[:session_id]

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def new_laptop
    @session_av_requirement = SessionAvRequirement.new

    @session_id = params[:session_id]

    respond_to do |format|
      format.html { render:'specify_laptop' }
    end
  end

  def create_laptop

    @session_av_requirement = SessionAvRequirement.new(session_av_requirement_params)

    speaker = get_speaker
    if (speaker!=nil) then
      @session_av_requirement.speaker_id = speaker.id
    end

    #add the laptop requirement selected
    av_list_item = AvListItem.where(name:'Laptop Selection').first
    @session_av_requirement.av_list_item = av_list_item
    @session_av_requirement.additional_notes = params[:select_laptop]

    respond_to do |format|
      if @session_av_requirement.save
        format.html { redirect_to("/session_av_requirements/#{@session_av_requirement.session_id}/index", :notice => 'AV Request successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end

  end

  def create

    @session_av_requirement = SessionAvRequirement.new(session_av_requirement_params)

    speaker = get_speaker
    if (speaker!=nil) then
      @session_av_requirement.speaker_id = speaker.id
    end

    respond_to do |format|
      if @session_av_requirement.save!
        format.html { redirect_to("/session_av_requirements/#{@session_av_requirement.session_id}/index", :notice => 'AV Request successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end

  end

  def edit
    @session_av_requirement = SessionAvRequirement.find(params[:id])

    @session_id = @session_av_requirement.session_id
    @speaker_id = @session_av_requirement.speaker_id

  end

  def update
    @session_av_requirement = SessionAvRequirement.find(params[:id])

    speaker = get_speaker
    if (speaker!=nil) then
      @session_av_requirement.speaker_id = speaker.id
    end

    respond_to do |format|
      if @session_av_requirement.update!(session_av_requirement_params)
        format.html { redirect_to("/session_av_requirements/#{@session_av_requirement.session_id}/index", :notice => 'AV Request successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end

  end

  def destroy
    @session_av_requirement = SessionAvRequirement.find(params[:id])
    session_id = @session_av_requirement.session_id
    @session_av_requirement.delete

    respond_to do |format|
        format.html { redirect_to("/session_av_requirements/#{session_id}/index", :notice => 'AV Request successfully deleted.') }
    end
  end


  private

  def set_layout
    if current_user.role? :trackowner then
      session[:layout]
    elsif current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def get_speaker
    user = User.find(current_user.id)
    speakers = Speaker.where(email:user.email,event_id:session[:event_id])

    if (speakers!=nil) then
      return speakers.first
    else
      return nil
    end

  end

  private

  def session_av_requirement_params
    params.require(:session_av_requirement).permit(:event_id, :session_id, :speaker_id, :av_list_item_id, :additional_notes)
  end

end