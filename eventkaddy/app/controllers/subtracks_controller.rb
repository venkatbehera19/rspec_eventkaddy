class SubtracksController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  # GET /subtracks
  # GET /subtracks.xml
  def index
	if (session[:event_id]) then
		@subtracks = Subtrack.select('subtracks.*, tracks.name AS track_name').joins('LEFT OUTER JOIN tracks on tracks.id=subtracks.track_id').where("tracks.event_id= ?",session[:event_id]).order('tracks.name ASC')
	
	    respond_to do |format|
	      format.html #{ render :json => @exhibitors } # index.html.erb
	      format.xml  { render :xml => @subtracks }
	      format.json { render :json => @subtracks.to_json, :callback => params[:callback] } #render :json => @exhibitors }
	    end
    
    else
      redirect_to "/home/session_error"
    end
    
  end

  # GET /subtracks/1
  # GET /subtracks/1.xml
  def show
    @subtrack = Subtrack.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subtrack }
    end
  end

  # GET /subtracks/new
  # GET /subtracks/new.xml
  def new
    @subtrack = Subtrack.new
	
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @subtrack }
    end
  end

  # GET /subtracks/1/edit
  def edit
    @subtrack = Subtrack.find(params[:id])
  end

  # POST /subtracks
  # POST /subtracks.xml
  def create
    @subtrack = Subtrack.new(subtrack_params)

    respond_to do |format|
      if @subtrack.save
        format.html { redirect_to(@subtrack, :notice => 'Subtrack was successfully created.') }
        format.xml  { render :xml => @subtrack, :status => :created, :location => @subtrack }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @subtrack.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /subtracks/1
  # PUT /subtracks/1.xml
  def update
    @subtrack = Subtrack.find(params[:id])

    respond_to do |format|
      if @subtrack.update!(subtrack_params)
        format.html { redirect_to(@subtrack, :notice => 'Subtrack was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subtrack.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /subtracks/1
  # DELETE /subtracks/1.xml
  def destroy
    @subtrack = Subtrack.find(params[:id])
    @subtrack.destroy

    respond_to do |format|
      format.html { redirect_to(subtracks_url) }
      format.xml  { head :ok }
    end
  end
  
  private

  def subtrack_params
    params.require(:subtrack).permit(:name, :description, :track_id)
  end

end