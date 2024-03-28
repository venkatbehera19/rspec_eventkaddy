class EnhancedListingsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  # GET /enhanced_listings
  # GET /enhanced_listings.xml
  def index
    @enhanced_listings = EnhancedListing.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @enhanced_listings }
    end
  end

  # GET /enhanced_listings/1
  # GET /enhanced_listings/1.xml
  def show
    @enhanced_listing = EnhancedListing.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @enhanced_listing }
    end
  end

  # GET /enhanced_listings/new
  # GET /enhanced_listings/new.xml
  def new
    @enhanced_listing = EnhancedListing.new

	@exhibitor_id = params[:exhibitor_id]
	
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @enhanced_listing }
    end
  end

  # GET /enhanced_listings/1/edit
  def edit
    @enhanced_listing = EnhancedListing.find(params[:id])
  	@exhibitor_id = @enhanced_listing.exhibitor_id
  end

  # POST /enhanced_listings
  # POST /enhanced_listings.xml
  def create
    @enhanced_listing = EnhancedListing.new(enhanced_listing_params)

    respond_to do |format|
      if @enhanced_listing.save
        format.html { redirect_to("/exhibitors/#{@enhanced_listing.exhibitor_id}", :notice => 'Enhanced listing was successfully created.') }
        format.xml  { render :xml => @enhanced_listing, :status => :created, :location => @enhanced_listing }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @enhanced_listing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /enhanced_listings/1
  # PUT /enhanced_listings/1.xml
  def update
    @enhanced_listing = EnhancedListing.find(params[:id])

    respond_to do |format|
      if @enhanced_listing.update!(enhanced_listing_params)
        format.html { redirect_to("/exhibitors/#{@enhanced_listing.exhibitor_id}", :notice => 'Enhanced listing was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @enhanced_listing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /enhanced_listings/1
  # DELETE /enhanced_listings/1.xml
  def destroy
    @enhanced_listing = EnhancedListing.find(params[:id])
    @enhanced_listing.destroy

    respond_to do |format|
      format.html { redirect_to("/exhibitors/#{@enhanced_listing.exhibitor_id}") }
      format.xml  { head :ok }
    end
  end

  private

  def enhanced_listing_params
    params.require(:enhanced_listing).permit(:exhibitor_id, :event_file_id, :product_name, :product_image, :product_description, :product_link)
  end

end