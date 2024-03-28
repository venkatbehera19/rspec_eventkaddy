class EventFileTypesController < ApplicationController
  # GET /event_file_types
  # GET /event_file_types.xml
  def index
    @event_file_types = EventFileType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @event_file_types }
    end
  end

  # GET /event_file_types/1
  # GET /event_file_types/1.xml
  def show
    @event_file_type = EventFileType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event_file_type }
    end
  end

  # GET /event_file_types/new
  # GET /event_file_types/new.xml
  def new
    @event_file_type = EventFileType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event_file_type }
    end
  end

  # GET /event_file_types/1/edit
  def edit
    @event_file_type = EventFileType.find(params[:id])
  end

  # POST /event_file_types
  # POST /event_file_types.xml
  def create
    @event_file_type = EventFileType.new(event_file_type_params)

    respond_to do |format|
      if @event_file_type.save
        format.html { redirect_to(@event_file_type, :notice => 'Event file type was successfully created.') }
        format.xml  { render :xml => @event_file_type, :status => :created, :location => @event_file_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event_file_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /event_file_types/1
  # PUT /event_file_types/1.xml
  def update
    @event_file_type = EventFileType.find(params[:id])

    respond_to do |format|
      if @event_file_type.update!(event_file_type_params)
        format.html { redirect_to(@event_file_type, :notice => 'Event file type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event_file_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /event_file_types/1
  # DELETE /event_file_types/1.xml
  def destroy
    @event_file_type = EventFileType.find(params[:id])
    @event_file_type.destroy

    respond_to do |format|
      format.html { redirect_to(event_file_types_url) }
      format.xml  { head :ok }
    end
  end

  private

    def event_file_type_params
      params.require(:event_file_type).permit(:name)
    end

end