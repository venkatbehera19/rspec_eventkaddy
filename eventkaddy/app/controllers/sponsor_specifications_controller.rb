class SponsorSpecificationsController < ApplicationController
  # GET /sponsor_specifications
  # GET /sponsor_specifications.xml
  load_and_authorize_resource
  
  
  def index
    @sponsor_specifications = SponsorSpecification.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sponsor_specifications }
    end
  end

  # GET /sponsor_specifications/1
  # GET /sponsor_specifications/1.xml
  def show
    @sponsor_specification = SponsorSpecification.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sponsor_specification }
    end
  end

  # GET /sponsor_specifications/new
  # GET /sponsor_specifications/new.xml
  def new
    @sponsor_specification = SponsorSpecification.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sponsor_specification }
    end
  end

  # GET /sponsor_specifications/1/edit
  def edit
    @sponsor_specification = SponsorSpecification.find(params[:id])
  end

  # POST /sponsor_specifications
  # POST /sponsor_specifications.xml
  def create
    @sponsor_specification = SponsorSpecification.new(sponsor_specification_params)

    respond_to do |format|
      if @sponsor_specification.save
        format.html { redirect_to(@sponsor_specification, :notice => 'Sponsor specification was successfully created.') }
        format.xml  { render :xml => @sponsor_specification, :status => :created, :location => @sponsor_specification }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sponsor_specification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sponsor_specifications/1
  # PUT /sponsor_specifications/1.xml
  def update
    @sponsor_specification = SponsorSpecification.find(params[:id])

    respond_to do |format|
      if @sponsor_specification.update!(sponsor_specification_params)
        format.html { redirect_to(@sponsor_specification, :notice => 'Sponsor specification was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sponsor_specification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sponsor_specifications/1
  # DELETE /sponsor_specifications/1.xml
  def destroy
    @sponsor_specification = SponsorSpecification.find(params[:id])
    @sponsor_specification.destroy

    respond_to do |format|
      format.html { redirect_to(sponsor_specifications_url) }
      format.xml  { head :ok }
    end
  end

  private

  def sponsor_specification_params
    params.require(:sponsor_specification).permit(:exhibitor_id, :sponsor_level_type, :banner_ad, :banner_ad_iphone, :banner_ad_android, :banner_ad_mobile, :banner_ad_home, :banner_ad_touch, :banner_ad_link)
  end

end