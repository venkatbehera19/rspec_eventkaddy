class SpeakerTypesController < ApplicationController
  # GET /speaker_types
  # GET /speaker_types.xml
  
  load_and_authorize_resource
  
  def index
    @speaker_types = SpeakerType.all

    respond_to do |format|
      format.html #{ index.html.erb }
      format.xml  { render :xml => @speaker_types }
    end
  end

  # GET /speaker_types/1
  # GET /speaker_types/1.xml
  def show
    @speaker_type = SpeakerType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @speaker_type }
    end
  end

  # GET /speaker_types/new
  # GET /speaker_types/new.xml
  def new
    @speaker_type = SpeakerType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @speaker_type }
    end
  end

  # GET /speaker_types/1/edit
  def edit
    @speaker_type = SpeakerType.find(params[:id])
  end

  # POST /speaker_types
  # POST /speaker_types.xml
  def create
    @speaker_type = SpeakerType.new(speaker_type_params)

    respond_to do |format|
      if @speaker_type.save
        format.html { redirect_to(@speaker_type, :notice => 'Speaker type was successfully created.') }
        format.xml  { render :xml => @speaker_type, :status => :created, :location => @speaker_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @speaker_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /speaker_types/1
  # PUT /speaker_types/1.xml
  def update
    @speaker_type = SpeakerType.find(params[:id])

    respond_to do |format|
      if @speaker_type.update!(speaker_type_params)
        format.html { redirect_to(@speaker_type, :notice => 'Speaker type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @speaker_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /speaker_types/1
  # DELETE /speaker_types/1.xml
  def destroy
    @speaker_type = SpeakerType.find(params[:id])
    @speaker_type.destroy

    respond_to do |format|
      format.html { redirect_to(speaker_types_url) }
      format.xml  { head :ok }
    end
  end
  
  private

  def speaker_type_params
    params.require(:speaker_type).permit(:speaker_type)
  end

end