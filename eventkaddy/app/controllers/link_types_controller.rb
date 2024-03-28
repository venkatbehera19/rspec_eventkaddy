class LinkTypesController < ApplicationController
  # GET /link_types
  # GET /link_types.xml
  def index
    @link_types = LinkType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @link_types }
    end
  end

  # GET /link_types/1
  # GET /link_types/1.xml
  def show
    @link_type = LinkType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @link_type }
    end
  end

  # GET /link_types/new
  # GET /link_types/new.xml
  def new
    @link_type = LinkType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @link_type }
    end
  end

  # GET /link_types/1/edit
  def edit
    @link_type = LinkType.find(params[:id])
  end

  # POST /link_types
  # POST /link_types.xml
  def create
    @link_type = LinkType.new(link_type_params)

    respond_to do |format|
      if @link_type.save
        format.html { redirect_to(@link_type, :notice => 'Link type was successfully created.') }
        format.xml  { render :xml => @link_type, :status => :created, :location => @link_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @link_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /link_types/1
  # PUT /link_types/1.xml
  def update
    @link_type = LinkType.find(params[:id])

    respond_to do |format|
      if @link_type.update!(link_type_params)
        format.html { redirect_to(@link_type, :notice => 'Link type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @link_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /link_types/1
  # DELETE /link_types/1.xml
  def destroy
    @link_type = LinkType.find(params[:id])
    @link_type.destroy

    respond_to do |format|
      format.html { redirect_to(link_types_url) }
      format.xml  { head :ok }
    end
  end

  private

  def link_type_params
    params.require(:link_type).permit(:link_type)
  end

end