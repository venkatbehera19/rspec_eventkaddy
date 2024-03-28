class ExhibitorLinksController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  # GET /exhibitor_links
  # GET /exhibitor_links.xml
  def index
    @exhibitor_links = ExhibitorLink.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @exhibitor_links }
    end
  end

  # GET /exhibitor_links/1
  # GET /exhibitor_links/1.xml
  def show
    @exhibitor_link = ExhibitorLink.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @exhibitor_link }
    end
  end

  # GET /exhibitor_links/new
  # GET /exhibitor_links/new.xml
  def new
    @exhibitor_link = ExhibitorLink.new
	@exhibitor_id = params[:exhibitor_id]
	
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @exhibitor_link }
    end
  end

  # GET /exhibitor_links/1/edit
  def edit
    @exhibitor_link = ExhibitorLink.find(params[:id])
  	@exhibitor_id = @exhibitor_link.exhibitor_id
  
  end

  # POST /exhibitor_links
  # POST /exhibitor_links.xml
  def create
    @exhibitor_link = ExhibitorLink.new(exhibitor_link_params)

    respond_to do |format|
      if @exhibitor_link.save
        format.html { redirect_to("/exhibitors/#{@exhibitor_link.exhibitor_id}", :notice => 'Exhibitor link was successfully created.') }
        format.xml  { render :xml => @exhibitor_link, :status => :created, :location => @exhibitor_link }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @exhibitor_link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /exhibitor_links/1
  # PUT /exhibitor_links/1.xml
  def update
    @exhibitor_link = ExhibitorLink.find(params[:id])

    respond_to do |format|
      if @exhibitor_link.update!(exhibitor_link_params)
        format.html { redirect_to("/exhibitors/#{@exhibitor_link.exhibitor_id}", :notice => 'Exhibitor link was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exhibitor_link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /exhibitor_links/1
  # DELETE /exhibitor_links/1.xml
  def destroy
    @exhibitor_link = ExhibitorLink.find(params[:id])
    @exhibitor_link.destroy

    respond_to do |format|
      format.html { redirect_to("/exhibitors/#{@exhibitor_link.exhibitor_id}") }
      format.xml  { head :ok }
    end
  end

  private

  def exhibitor_link_params
    params.require(:exhibitor_link).permit(:exhibitor_id, :event_file_id, :name, :url)
  end

end