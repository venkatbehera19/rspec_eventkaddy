class SpeakerFilesController < ApplicationController
  layout :set_layout

  load_and_authorize_resource

  before_action :set_layout_variables

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

    @speaker_id = params[:speaker_id]

    if (current_user.role? :trackowner)
      @speaker = Speaker.where(id:@speaker_id,event_id:session[:event_id]).first
    elsif current_user.role? :speaker
      @speaker = get_speaker
      if params[:speaker_id] != @speaker.id.to_s
        raise "You do not have access to this Speaker's files."
      end
    else
      @speaker = Speaker.where(id:@speaker_id,event_id:session[:event_id]).first
    end

    #retrieve existing pdfs
    @event_file_type = EventFileType.where(name:'speaker_pdf_upload').first
    @pdf_files       = EventFile.where(event_id:@speaker.event_id,event_file_type_id:@event_file_type.id)
    @event_file_type = EventFileType.where(name:'speaker_pdf_no_sign').first
    @info_pdf_files  = EventFile.where(event_id:@speaker.event_id,event_file_type_id:@event_file_type.id)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @speaker_file         = SpeakerFile.new
    @speaker_id           = params[:speaker_id]
    @original_document_id = params[:original_document_id]

    if (current_user.role? :trackowner)
    elsif current_user.role? :speaker
      @speaker = get_speaker
      puts @speaker.id
      puts params[:speaker_id]
      if params[:speaker_id] != @speaker.id.to_s
        raise "You do not have access to this Speaker's files."
      end
    end

    respond_to do |format|
      format.html # new.html.erb
    end

  end

  def create

    @speaker_file          = SpeakerFile.new(speaker_file_params)
    @speaker_file.document = params[:event_file]
    @original_document_id  = params[:speaker_file][:original_document_id]
    @original_document     = EventFile.where(id:@original_document_id).first
    puts "----------- #{@original_document_id} ----------"

    #set speaker
    # @speaker_file.speaker_id = params[:speaker_id]
    @speaker_file.speaker_file_type    = SpeakerFileType.where(name:"signed document").first #hard code for signed document type
    @speaker_file.original_document_id = @original_document_id


    @speaker_file.updateFile(params)

    respond_to do |format|
      if @speaker_file.save
      	if @speaker_file.title.blank?
	      @speaker_file.update!(:title => @original_document.name)
	    end
        if current_user.role? :speaker then
          format.html { redirect_to("/speaker_portals/download_pdf", :notice => 'Speaker file successfully created.') }
        else
          format.html { redirect_to("/speaker_files/#{@speaker_file.speaker_id}/index", :notice => 'Speaker file successfully created.') }
        end
      else
        format.html { redirect_to("/speaker_files/#{@speaker_file.speaker_id}/new/#{@original_document_id}", :notice => @speaker_file.errors.full_messages[0] ) }
      end
    end

  end

  def edit
    @speaker_file = SpeakerFile.find(params[:id])
    @speaker_id   = @speaker_file.speaker_id
    @original_document_id = @speaker_file.original_document_id

    if (current_user.role? :trackowner)
    elsif current_user.role? :speaker
      @speaker = get_speaker
      if @speaker_id != @speaker.id
        raise "You do not have access to this Speaker's files."
      end
    end

  end

  def update
    @speaker_file          = SpeakerFile.find(params[:id])
    @speaker_file.document = params[:event_file]
    @speaker_file.updating = true
    @original_document     = EventFile.where(id:@speaker_file.original_document_id).first
    #set speaker

    @speaker_file.updateFile(params)


    respond_to do |format|
      if @speaker_file.update!(speaker_file_params)
	    if @speaker_file.title.blank?
	      @speaker_file.update!(:title => @original_document.name)
	    end
        if current_user.role? :speaker then
          format.html { redirect_to("/speaker_portals/download_pdf", :notice => 'Speaker file successfully updated.') }
        else
          format.html { redirect_to("/speaker_files/#{@speaker_file.speaker_id}/index", :notice => 'Speaker file successfully updated.') }
        end
      else
        format.html { redirect_to("/speaker_files/#{@speaker_file.id}/edit", :notice => @speaker_file.errors.full_messages[0]) }
      end
    end

  end

  def destroy
    @speaker_file = SpeakerFile.find(params[:id])
    # @speaker_file.deleteFile(params)
    @speaker_file.destroy

    respond_to do |format|
        if current_user.role? :speaker then
          format.html { redirect_to("/speaker_portals/download_pdf", :notice => 'Speaker file successfully removed.') }
        else
          format.html { redirect_to("/speaker_files/#{@speaker_file.speaker_id}/index", :notice => 'Speaker file successfully removed.') }
        end
    end
  end

  private

    def get_speaker
      user = User.find(current_user.id)
      return Speaker.where(email:user.email,event_id:session[:event_id]).first

    end

  def set_layout
    if current_user.role? :trackowner then
      session[:layout]
    elsif current_user.role? :speaker then
      'speakerportal_2013'
    else
      'subevent_2013'
    end
  end

  def speaker_file_params
    params.require(:speaker_file).permit(:description, :event_file_id, :event_id, :speaker_file_type, :speaker_id, 
      :title, :original_document_id
    )
  end

end