class ExhibitorFilesController < ApplicationController

  layout :set_layout
  load_and_authorize_resource

  def index
    @event_id        = session[:event_id]
    @exhibitor_id    = params[:exhibitor_id]
    file_type_id     = ExhibitorFileType.where(name:'exhibitor_document').first.id
    @exhibitor_files = ExhibitorFile.where(exhibitor_id:@exhibitor_id, exhibitor_file_type_id:file_type_id)
    @filetypes       = {"application/msword" => ".doc", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx", "application/vnd.oasis.opendocument.spreadsheet" => ".ods", "application/pdf" => ".pdf", "text/plain" => ".txt", "application/rtf" => ".rtf", "application/vnd.ms-powerpoint" => ".ppt", "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx", "application/vnd.ms-excel" => ".xls", "application/xlsx" => ".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => ".xlsx", "video/quicktime" => ".mov", "video/mp4" => ".mp4", "audio/mpeg" => ".mp3", "application/octet-stream" => ".pez"}
  end

  def new
    @exhibitor_file       = ExhibitorFile.new
    @exhibitor_id         = params[:exhibitor_id]
    @original_document_id = params[:original_document_id]
    @title                = params[:title]
  end

  def create
    @saved = false
    if params[:event_files]
      params[:event_files].each do |f|
        # binding.pry
        @exhibitor_file                        = ExhibitorFile.new exhibitor_file_params
        @exhibitor_file.document               = f
        @exhibitor_file.title                  = f.original_filename if params[:event_files].length > 1 # overwrite title input with filename if multiple files
        @exhibitor_file.exhibitor_file_type_id = ExhibitorFileType.where(name:'exhibitor_document').first.id
        @saved = @exhibitor_file.save!
        @exhibitor_file.updateFile params if @saved
      end
    end
    respond_to do |format|
      if !@exhibitor_file.errors.empty?
        @exhibitor_file.destroy if @saved # removed the record we created, as something went wrong
        format.html { redirect_to("/exhibitor_files/#{params[:exhibitor_file][:exhibitor_id]}/new", :alert => "#{@exhibitor_file.errors.full_messages[0]}")}
      elsif @saved
        if params[:is_exhibitor_portal].present?
          format.html { redirect_to("/exhibitor_portals/download_pdf", :notice => 'Exhibitor File successfully created.') }
        else
          format.html { redirect_to("/exhibitor_files/#{@exhibitor_file.exhibitor_id}/index", :notice => 'Exhibitor File successfully created.') }
        end
      else #no event files
        format.html { redirect_to("/exhibitor_files/#{params[:exhibitor_file][:exhibitor_id]}/new", :alert => "Please select a file to upload.")}
      end
    end
  end

  def edit
    @exhibitor_file = ExhibitorFile.find(params[:id])
    @exhibitor_id   = @exhibitor_file.exhibitor_id
  end

  def update
    @exhibitor_file          = ExhibitorFile.find(params[:id])
    @exhibitor_file.updating = true
    updated                  = @exhibitor_file.update! params[:exhibitor_file]

    if params[:event_files]
      @exhibitor_file.document = params[:event_files].first
      @exhibitor_file.updateFile params
    else
      @exhibitor_file.update_json_entry params
    end

    respond_to do |format|
      if updated && !@exhibitor_file.errors.empty?
        format.html { redirect_to("/exhibitor_files/#{@exhibitor_file.id}/edit", :alert => @exhibitor_file.errors.full_messages[0]) }
      elsif @exhibitor_file.update!(exhibitor_file_params)
        format.html { redirect_to("/exhibitor_files/#{@exhibitor_file.exhibitor_id}/index", :notice => 'Exhibitor File successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    exhibitor_file = ExhibitorFile.find params[:id]
    exhibitor_file.destroy
    respond_to do |format|
      if params[:exhibitor_portals].present?
        format.html { redirect_to("/exhibitor_portals/download_pdf", :notice => 'Exhibitor File successfully deleted.') }
      else
        format.html { redirect_to("/exhibitor_files/#{exhibitor_file.exhibitor_id}/index", :notice => 'Exhibitor File successfully deleted.') }
      end
    end
  end

  private

  def get_speaker
    user = User.find(current_user.id)
    Speaker.where(email:user.email, event_id:session[:event_id]).first
  end

  def set_layout
    if current_user.role? :trackowner
      session[:layout]
    elsif current_user.role? :speaker
      'speakerportal_2013'
    elsif current_user.role? :exhibitor
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  def exhibitor_file_params
    params.require(:exhibitor_file).permit(:event_id, :exhibitor_id, :event_file_id, :title, :description, :exhibitor_file_type_id, :original_document_id)
  end

end
