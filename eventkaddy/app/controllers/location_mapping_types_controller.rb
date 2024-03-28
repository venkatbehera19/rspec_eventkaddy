class LocationMappingTypesController < ApplicationController
  # GET /location_mapping_types
  # GET /location_mapping_types.xml
  def index
    @location_mapping_types = LocationMappingType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @location_mapping_types }
    end
  end

  # GET /location_mapping_types/1
  # GET /location_mapping_types/1.xml
  def show
    @location_mapping_type = LocationMappingType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @location_mapping_type }
    end
  end

  # GET /location_mapping_types/new
  # GET /location_mapping_types/new.xml
  def new
    @location_mapping_type = LocationMappingType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @location_mapping_type }
    end
  end

  # GET /location_mapping_types/1/edit
  def edit
    @location_mapping_type = LocationMappingType.find(params[:id])
  end

  # POST /location_mapping_types
  # POST /location_mapping_types.xml
  def create
    @location_mapping_type = LocationMappingType.new(location_mapping_type_params)

    respond_to do |format|
      if @location_mapping_type.save
        format.html { redirect_to(@location_mapping_type, :notice => 'Location mapping type was successfully created.') }
        format.xml  { render :xml => @location_mapping_type, :status => :created, :location => @location_mapping_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @location_mapping_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /location_mapping_types/1
  # PUT /location_mapping_types/1.xml
  def update
    @location_mapping_type = LocationMappingType.find(params[:id])

    respond_to do |format|
      if @location_mapping_type.update!(location_mapping_type_params)
        format.html { redirect_to(@location_mapping_type, :notice => 'Location mapping type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location_mapping_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /location_mapping_types/1
  # DELETE /location_mapping_types/1.xml
  def destroy
    @location_mapping_type = LocationMappingType.find(params[:id])
    @location_mapping_type.destroy

    respond_to do |format|
      format.html { redirect_to(location_mapping_types_url) }
      format.xml  { head :ok }
    end
  end

  private

  def location_mapping_type_params
    params.require(:location_mapping_type).permit(:type_name)
  end

end