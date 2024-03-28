class LocationMappingsController < ApplicationController
  layout 'subevent_2013'

  load_and_authorize_resource :except => [:mapping_product]

  skip_before_action :verify_authenticity_token, :only => [:update_coordinate, :update_size]

  def select_map
    @maps = EventMap.where(event_id:session[:event_id])
  end

  def set_coordinates
    @map               = EventMap.find(params[:map_id])
    null_location_mappings = LocationMapping.where(map_id:params[:map_id], x:nil, y:nil).order('name')
    @location_mappings = null_location_mappings + LocationMapping.where(map_id:params[:map_id]).where('x IS NOT NULL').order('name')
    @coordinates = []

    @location_mappings.each_with_index do |mapping|

      if mapping.y && mapping.x
        top  = mapping.y - (mapping.height ? mapping.height / 2 : 12)
        left = mapping.x - (mapping.width ? mapping.width / 2 : 12)
      else
        #hide offscreen
        top  = -2000
        left = -2000
      end

      @coordinates << {id: mapping.id, top:top, left:left, text:mapping.name, width: mapping.width, height: mapping.height}
    end

    @coordinates       = @coordinates.to_json
    @location_mappings = @location_mappings.to_json.gsub /'/ do %q(\') end

    respond_to do |format|
      format.html { render :layout => false  }
    end

  end

  def update_coordinate
    JSON.parse(params[:Coordinate]).each do |c|
      lm = LocationMapping.find c["id"]
      lm.update!(x:c["x"], y: c["y"]) if lm.event_id == session[:event_id]
    end
    render json: { nothing: true }
  end

  def update_size
    lm = LocationMapping.find(params[:id])
    if lm.update(width: params[:width], height: params[:height], x: params[:x], y: params[:y])
      render json: {notice: "Location Mapping size has been updated"}
    else
      render json: {alert: lm.errors.full_messages}
    end
  end

  def index
    @location_mappings = LocationMapping.all

	if (session[:event_id]) then
		@location_mappings = LocationMapping.select('location_mappings.*, location_mapping_types.type_name AS location_mapping_type_name').joins('
		LEFT OUTER JOIN location_mapping_types ON location_mapping_types.id=location_mappings.mapping_type').
		where("location_mappings.event_id= ?",session[:event_id])

	    respond_to do |format|
	      format.html # index.html.erb
	      format.xml  { render :xml => @location_mappings }
	      format.json { render :json => @locatio_mappings.to_json, :callback => params[:callback] }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  def rooms_index

	if (session[:event_id]) then
		@location_mappings = LocationMapping.select('location_mappings.*, location_mapping_types.type_name AS location_mapping_type_name').joins('
		LEFT OUTER JOIN location_mapping_types ON location_mapping_types.id=location_mappings.mapping_type').
		where("location_mappings.event_id= ? AND location_mapping_types.type_name= ?",session[:event_id],"Room")

	    respond_to do |format|
	      format.html { render :index }
	      format.xml  { render :xml => @location_mappings }
	      format.json { render :json => @locatio_mappings.to_json, :callback => params[:callback] }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  def booths_index

	if (session[:event_id]) then
		@location_mappings = LocationMapping.select('location_mappings.*, location_mapping_types.type_name AS location_mapping_type_name').joins('
		LEFT OUTER JOIN location_mapping_types ON location_mapping_types.id=location_mappings.mapping_type').
		where("location_mappings.event_id= ? AND location_mapping_types.type_name= ?",session[:event_id],"Booth")

	    respond_to do |format|
	      format.html { render :index }
	      format.xml  { render :xml => @location_mappings }
	      format.json { render :json => @locatio_mappings.to_json, :callback => params[:callback] }
	    end

    else
      redirect_to "/home/session_error"
    end

  end

  # GET /location_mappings/1
  # GET /location_mappings/1.xml
  def show
    @location_mapping = LocationMapping.find(params[:id])

	@event_map = EventMap.joins('LEFT OUTER JOIN location_mappings on location_mappings.map_id=event_maps.id').where('location_mappings.id= ?',@location_mapping.id).first

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @location_mapping }
    end
  end

  # GET /location_mappings/new
  # GET /location_mappings/new.xml
  def new
    @location_mapping = LocationMapping.new

	@event_maps = EventMap.where("event_maps.event_id= ?",session[:event_id])


    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @location_mapping }
    end
  end

  # GET /location_mappings/1/edit
  def edit
    @location_mapping = LocationMapping.find(params[:id])
	@event_maps = EventMap.where("event_maps.event_id= ?",session[:event_id])

  end

  # POST /location_mappings
  # POST /location_mappings.xml
  def create
    @location_mapping = LocationMapping.new(location_mapping_params)

    respond_to do |format|
      if @location_mapping.save
        format.html { redirect_to(@location_mapping, :notice => 'Location mapping was successfully created.') }
        format.xml  { render :xml => @location_mapping, :status => :created, :location => @location_mapping }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @location_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /location_mappings/1
  # PUT /location_mappings/1.xml
  def update
    @location_mapping = LocationMapping.find(params[:id])
    respond_to do |format|
      if @location_mapping.update!(location_mapping_params)
        @location_mapping.sessions.each do |s|
          s.update_column(:updated_at, Time.now)
        end
        @location_mapping.exhibitors.each do |e|
          e.update_column(:updated_at, Time.now)
        end
        format.html { redirect_to(@location_mapping, :notice => 'Location mapping was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /location_mappings/1
  # DELETE /location_mappings/1.xml
  def destroy
    @location_mapping = LocationMapping.find(params[:id])
    @location_mapping.destroy

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.xml  { head :ok }
    end
  end

  def remove_association
    respond_to do |format|
      if LocationMapping.find(params[:id]).update_attribute(:map_id, nil)
        format.html { redirect_back fallback_location: root_path, notice: 'Location mapping association to map removed.' }
      else
        format.html { redirect_back fallback_location: root_path, alert: 'An error occured while trying to remove location mapping from map..' }
      end
    end
  end

  def location_mapping_products
    message = 'nothing happened'
    location_mapping = LocationMapping.find_by(id: params[:location_mapping][:location_mapping])
    product = Product.find_by(id: params[:location_mapping][:product])
    if location_mapping && product
      LocationMappingProduct.where(location_mapping_id: location_mapping.id).select do |record|
        if record.product_id != product.id
          record.destroy
        end
      end
      LocationMappingProduct.find_or_create_by(location_mapping_id: location_mapping.id, product_id: product.id)
      message = 'success'
    end
    render json: {status: :ok, message: message}
  end

  def mapping_product
    location_mappings = LocationMapping.joins(:products).where(id: params[:location_mapping_id])
    if location_mappings.present?
      render json: { status: true, data: location_mappings.first.products.first }
      return
    end
    render json: { status: :unprocessable_entity }
  end

  private

  def location_mapping_params
    params.require(:location_mapping).permit(:event_id, :map_id, :name, :mapping_type, :x, :y, :booth_size_type_id, :location_mapping, :product)
  end

end
