class SessionsSubtracksController < ApplicationController
  # GET /sessions_subtracks
  # GET /sessions_subtracks.xml
  load_and_authorize_resource
  
  def index
    @sessions_subtracks = SessionsSubtrack.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sessions_subtracks }
    end
  end

  # GET /sessions_subtracks/1
  # GET /sessions_subtracks/1.xml
  def show
    @sessions_subtrack = SessionsSubtrack.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sessions_subtrack }
    end
  end

  # GET /sessions_subtracks/new
  # GET /sessions_subtracks/new.xml
  def new
    @sessions_subtrack = SessionsSubtrack.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sessions_subtrack }
    end
  end

  # GET /sessions_subtracks/1/edit
  def edit
    @sessions_subtrack = SessionsSubtrack.find(params[:id])
  end

  # POST /sessions_subtracks
  # POST /sessions_subtracks.xml
  def create
    @sessions_subtrack = SessionsSubtrack.new(sessions_subtrack_params)

    respond_to do |format|
      if @sessions_subtrack.save
        format.html { redirect_to(@sessions_subtrack, :notice => 'Sessions subtrack was successfully created.') }
        format.xml  { render :xml => @sessions_subtrack, :status => :created, :location => @sessions_subtrack }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sessions_subtrack.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sessions_subtracks/1
  # PUT /sessions_subtracks/1.xml
  def update
    @sessions_subtrack = SessionsSubtrack.find(params[:id])

    respond_to do |format|
      if @sessions_subtrack.update!(sessions_subtrack_params)
        format.html { redirect_to(@sessions_subtrack, :notice => 'Sessions subtrack was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sessions_subtrack.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sessions_subtracks/1
  # DELETE /sessions_subtracks/1.xml
  def destroy
    @sessions_subtrack = SessionsSubtrack.find(params[:id])
    @sessions_subtrack.destroy

    respond_to do |format|
      format.html { redirect_to(sessions_subtracks_url) }
      format.xml  { head :ok }
    end
  end

  private

  def sessions_subtrack_params
    params.require(:sessions_subtrack).permit(:subtrack_id, :session_id)
  end

end