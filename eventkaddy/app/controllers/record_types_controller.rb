class RecordTypesController < ApplicationController
  # GET /record_types
  # GET /record_types.xml
  load_and_authorize_resource
  
  def index
    @record_types = RecordType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @record_types }
    end
  end

  # GET /record_types/1
  # GET /record_types/1.xml
  def show
    @record_type = RecordType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @record_type }
    end
  end

  # GET /record_types/new
  # GET /record_types/new.xml
  def new
    @record_type = RecordType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @record_type }
    end
  end

  # GET /record_types/1/edit
  def edit
    @record_type = RecordType.find(params[:id])
  end

  # POST /record_types
  # POST /record_types.xml
  def create
    @record_type = RecordType.new(record_type_params)

    respond_to do |format|
      if @record_type.save
        format.html { redirect_to(@record_type, :notice => 'Record type was successfully created.') }
        format.xml  { render :xml => @record_type, :status => :created, :location => @record_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @record_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /record_types/1
  # PUT /record_types/1.xml
  def update
    @record_type = RecordType.find(params[:id])

    respond_to do |format|
      if @record_type.update!(record_type_params)
        format.html { redirect_to(@record_type, :notice => 'Record type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @record_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /record_types/1
  # DELETE /record_types/1.xml
  def destroy
    @record_type = RecordType.find(params[:id])
    @record_type.destroy

    respond_to do |format|
      format.html { redirect_to(record_types_url) }
      format.xml  { head :ok }
    end
  end

  private

  def record_type_params
    params.require(:record_type).permit(:record_type)
  end

end