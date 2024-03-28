class SessionsSpeakersController < ApplicationController
  # GET /sessions_speakers
  # GET /sessions_speakers.xml
  load_and_authorize_resource
  
  def index
    @sessions_speakers = SessionsSpeaker.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sessions_speakers }
    end
  end

  # GET /sessions_speakers/1
  # GET /sessions_speakers/1.xml
  def show
    @sessions_speaker = SessionsSpeaker.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sessions_speaker }
    end
  end

  # GET /sessions_speakers/new
  # GET /sessions_speakers/new.xml
  def new
    @sessions_speaker = SessionsSpeaker.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sessions_speaker }
    end
  end

  # GET /sessions_speakers/1/edit
  def edit
    @sessions_speaker = SessionsSpeaker.find(params[:id])
  end

  # POST /sessions_speakers
  # POST /sessions_speakers.xml
  def create
    @sessions_speaker = SessionsSpeaker.new(sessions_speaker_params)

    respond_to do |format|
      if @sessions_speaker.save
        format.html { redirect_back(fallback_location: root_url, :notice => 'Sessions was successfully added to the speaker.') }
        #format.xml  { render :xml => @sessions_speaker, :status => :created, :location => @sessions_speaker }
      end
    end
  end

  # PUT /sessions_speakers/1
  # PUT /sessions_speakers/1.xml
  def update
    @sessions_speaker = SessionsSpeaker.find(params[:id])

    respond_to do |format|
      if @sessions_speaker.update!(sessions_speaker_params)
        format.html { redirect_to(@sessions_speaker, :notice => 'Sessions speaker was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sessions_speaker.errors, :status => :unprocessable_entity }
      end
    end
  end

  def toggle_unpublished
    sessions_speaker = SessionsSpeaker.find params[:id]
    sessions_speaker.update! unpublished: !sessions_speaker.unpublished
    redirect_back fallback_location: root_path
  end

  # DELETE /sessions_speakers/1
  # DELETE /sessions_speakers/1.xml
  def destroy
    @sessions_speaker = SessionsSpeaker.find(params[:id])
    @sessions_speaker.destroy

    respond_to do |format|
      format.html { redirect_to(sessions_speakers_url) }
      format.xml  { head :ok }
    end
  end

  private

  def sessions_speaker_params
    params.require(:sessions_speaker).permit(:session_id, :speaker_id, :unpublished, :is_moderator, :speaker_type_id)
  end

end