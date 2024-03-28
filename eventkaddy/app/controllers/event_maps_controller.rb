class EventMapsController < ApplicationController

  layout 'subevent_2013'

  load_and_authorize_resource

  def mobile_data

   @empty_data = "[]"

	if (params[:event_id]) then
		@event_maps = EventMap.select('event_maps.*,event_files.path AS file_url').joins('
		LEFT OUTER JOIN event_files ON event_maps.map_event_file_id=event_files.id'
		).where("event_maps.event_id= ? AND event_maps.id > ?",params[:event_id],params[:record_start_id]).order('event_maps.id ASC').limit(100)

		if (@event_maps.length > 0) then
			render :json => @event_maps.to_json, :callback => params[:callback]
		else
			render :json => @empty_data, :callback => params[:callback]
		end

    end

  end

  def add_rooms
    @event_map         = EventMap.find(params[:map_id])
    @location_mappings = LocationMapping.where(event_id:session[:event_id])
  end

  def update_add_rooms
    location_mappings = params[:location_mapping_ids]
    @event_map        = EventMap.find(params[:map_id])

    location_mappings.each do |location_id|
      location_mapping        = LocationMapping.where(id:location_id).first
      location_mapping.update!(map_id: params[:map_id])
    end

    respond_to do |format|
      format.html { redirect_to "/event_maps/#{params[:map_id]}", :notice => 'Locations successfully added to map.' }
    end

  end

  def index

	if (session[:event_id]) then
		@event_maps = EventMap.where('event_id= ?',session[:event_id])

	    respond_to do |format|
	      format.html # index.html.erb
	      format.xml  { render :xml => @event_maps }
	      format.json { render :json => @event_maps.to_json, :callback => params[:callback] }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  def show
    @event_map = EventMap.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @event_map }
    end
  end

  def new
    @event_map = EventMap.new
    @map_types = MapType.all
    @map_types.reject {|t| t.map_type == 'Interactive Map'} unless File.exists? InteractiveMap::Symlink

    respond_to do |format|
      format.html
      format.xml  { render :xml => @event_map }
    end
  end

  def edit
    @event_map = EventMap.find(params[:id])
    @map_types = MapType.all
    @map_types.reject {|t| t.map_type == 'Interactive Map'} unless File.exists? InteractiveMap::Symlink
  end

  def create
    @event_map = EventMap.new event_map_params
	  @event_map.event_id = session[:event_id]
    results = []

    if @event_map.save validate: false
      results << {status: true, message: 'Successfully updated event map details.'}
      results << @event_map.update_image(params[:image_file]) if params[:image_file]
      results << @event_map.sync_interactive_map(originally_interactive = false)
    else
      results << {status: false, message: 'Event map was not saved.'}
    end

    respond_to do |format|
      if results[0][:status]
        notice = results.each_with_object('') {|result, m| m << "#{result[:message]} " if result[:status]}
        alert = results.each_with_object('') {|result, m| m << "#{result[:message]} " if !result[:status]}
        opts = {}
        opts[:notice] = notice unless notice.blank?
        opts[:alert] = alert unless alert.blank?
        format.html { redirect_to @event_map, opts }
      else
        format.html { render :action => "new", alert:results[0][:message] }
      end
    end
  end

  def update
    @event_map = EventMap.find(params[:id])
    results = []
    originally_interactive = @event_map.interactive_map?

    if @event_map.update! event_map_params
      results << {status: true, message: 'Successfully updated event map details.'}
      results << @event_map.update_image(params[:image_file]) if params[:image_file]
      results << @event_map.sync_interactive_map(originally_interactive)
    else
      results << {status: false, message: 'Event map was not saved.'}
    end

    respond_to do |format|
      if results[0][:status]
        notice = results.each_with_object('') {|result, m| m << "#{result[:message]} " if result[:status]}
        alert = results.each_with_object('') {|result, m| m << "#{result[:message]} " if !result[:status]}
        opts = {}
        opts[:notice] = notice unless notice.blank?
        opts[:alert] = alert unless alert.blank?
        format.html { redirect_to @event_map, opts }
      else
        format.html { render :action => "new", alert:results[0][:message] }
      end
    end
  end

  def destroy
    @event_map = EventMap.find(params[:id])
    @event_map.remove_interactive_map if @event_map.interactive_map?
    @event_map.destroy

    respond_to do |format|
      format.html { redirect_to(event_maps_url) }
      format.xml  { head :ok }
    end
  end

  private

  def event_map_params
    params.require(:event_map).permit(:event_id, :map_event_file_id, :name, :filename, :width, :height, :map_type_id, :external_map_url, :address_description)
  end

end