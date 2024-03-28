class LinksController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  # GET /links
  # GET /links.xml
  def index
    @links = Link.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @links }
    end
  end

  # GET /links/1
  # GET /links/1.xml
  def show
    @link = Link.find(params[:id])

	puts "SHOW LINK called"
	
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @link }
    end
  end

  # GET /links/new
  # GET /links/new.xml
  def new
    @link = Link.new
	
	@session_id= params[:session_id]	
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @link }
    end
  end

  # GET /links/1/edit
  def edit
    @link = Link.find(params[:id])
    @session_id= @link.session_id
  
  end

  # POST /links
  # POST /links.xml
  def create
    @link = Link.new(link_params)

    respond_to do |format|
      if @link.save validate: false
        format.html { redirect_to("/sessions/#{@link.session_id}", :notice => 'Link was successfully created.') }
        format.xml  { render :xml => @link, :status => :created, :location => @link }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /links/1
  # PUT /links/1.xml
  def update
    @link = Link.find(params[:id])

    respond_to do |format|
      if @link.update!(link_params)
        format.html { redirect_to("/sessions/#{@link.session_id}", :notice => 'Link was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /links/1
  # DELETE /links/1.xml
  def destroy
    @link = Link.find(params[:id])
    @link.delete
	
	puts "---DELETE LINK method called---"
	
    respond_to do |format|
      format.html { redirect_to("/sessions/#{@link.session_id}") }
      format.xml  { head :ok }
    end
  end

  private

  def link_params
    params.require(:link).permit(:session_id, :event_file_id, :name, :link_type_id, :filename)
  end

end