class TracksController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  def mobile_data

   @empty_data = "[]"
  
	if (params[:event_id]) then
		@tracks = Track.select('tracks.name as track_name,subtracks.name as subtrack_name, sessions.*, DATE_FORMAT(start_at,\'%H-%i\') AS start_at_formatted,DATE_FORMAT(end_at,\'%H-%i\') AS end_at_formatted,DATE_FORMAT(start_at,\'%l:%i %p\') AS start_at_12h,DATE_FORMAT(end_at,\'%l:%i %p\') AS end_at_12h,location_mappings.name as location_name,location_mappings.x AS location_x, location_mappings.y AS location_y, location_mappings.map_id AS map_id, sessions.id AS session_id').joins('
		LEFT OUTER JOIN subtracks ON subtracks.track_id=tracks.id
		LEFT OUTER JOIN sessions_subtracks on subtracks.id=sessions_subtracks.subtrack_id
		LEFT OUTER JOIN sessions on sessions.id=sessions_subtracks.session_id 
		LEFT OUTER JOIN location_mappings ON sessions.location_mapping_id=location_mappings.id
		').where("tracks.event_id= ? AND sessions.id > ?",params[:event_id],params[:record_start_id]).order('sessions.id ASC').limit(125)
		
		if (@tracks.length > 0) then
			render :json => @tracks.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end

    end
    
  end

  def index
  
	if (session[:event_id]) then
		@tracks = Track.where("event_id= ?",session[:event_id])
		
		@track = Track.new
	    
	    respond_to do |format|
	      format.html #{ render :json => @exhibitors } # index.html.erb
	      format.xml  { render :xml => @tracks }
	      format.json { render :json => @tracks.to_json, :callback => params[:callback] } #render :json => @exhibitors }
	    end
    
    else
      redirect_to "/home/session_error"
    end
  
  end

  # GET /tracks/1
  # GET /tracks/1.xml
  def show
    @track = Track.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @track }
    end
  end

  # GET /tracks/new
  # GET /tracks/new.xml
  def new
    @track = Track.new

    respond_to do |format|
      format.html { render :new } #/*, :layout => false } # new.html.erb
      format.xml  { render :xml => @track }
      format.js   { render :new }
    end
  end

  # GET /tracks/1/edit
  def edit
    @track = Track.find(params[:id])
  	
  end

  # POST /tracks
  # POST /tracks.xml
  def create
    @track = Track.new(track_params)
	@track.event_id=session[:event_id]
	
    respond_to do |format|
      if @track.save
        format.html { redirect_to(@track, :notice => 'Track was successfully created.') }
        format.xml  { render :xml => @track, :status => :created, :location => @track }
		  format.js 	{ render :create } #=> @track, :status => :created :location => @track, :layout => !request.xhr? }
		
      else
        format.html	{ render :action => "new" }
        format.xml	{ render :xml => @track.errors, :status => :unprocessable_entity }
        format.js 	{ render :create => @track.errors, :status => :unprocessable_entity }
      end
    end
  end


  # PUT /tracks/1
  # PUT /tracks/1.xml
  def update
    @track = Track.find(params[:id])

    respond_to do |format|
      if @track.update!(track_params)
        format.html { redirect_to(@track, :notice => 'Track was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @track.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tracks/1
  # DELETE /tracks/1.xml
  def destroy
    @track = Track.find(params[:id])
    @track.destroy

    respond_to do |format|
      format.html { redirect_to(tracks_url) }
      format.xml  { head :ok }
    end
  end

  private

  def track_params
    params.require(:track).permit(:name, :description, :event_id, :track_color)
  end

end