class OrganizationsController < ApplicationController
  layout "superadmin_2013"
  load_and_authorize_resource #:only => [:show,:new,:destroy,:edit,:update,:index]

  # GET /organizations
  # GET /organizations.xml
  def index
    @organizations = Organization.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organizations }
    end
  end

  def indexforuser

  	if (current_user!=nil) then
	  	@organizations = Organization.joins('LEFT OUTER JOIN users_organizations ON users_organizations.org_id=organizations.id').where("users_organizations.user_id = ?",current_user.id)

	    respond_to do |format|
	      format.html # index.html.erb
	      format.xml  { render :xml => @organizations }
	      format.json { render :json => @organizations.to_json, :callback => params[:callback] }
	    end

	 else

	 redirect_to '/home'
	 end

  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    @organization = Organization.find(params[:id])
    @events       = Event.where('org_id= ?',@organization.id)

    if @events.length > 0
      @domains = Domain.select('*, events.name AS event_name, domain_types.name AS type_name').
        joins('JOIN events ON events.id=domains.event_id').
        joins('JOIN domain_types ON domain_types.id=domains.domain_type_id').
        where("domains.event_id IN (#{@events.pluck(:id).join(',')})")
    else
      @domains = []
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    @organization = Organization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end

  # POST /organizations
  # POST /organizations.xml
  def create
    @organization = Organization.new(organization_params)

    respond_to do |format|
      if @organization.save
        format.html { redirect_to(@organization, :notice => 'Organization was successfully created.') }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    @organization = Organization.find(params[:id])

    respond_to do |format|
      if @organization.update!(organization_params)
        format.html { redirect_to(@organization, :notice => 'Organization was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.xml
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy

    respond_to do |format|
      format.html { redirect_to(organizations_url) }
      format.xml  { head :ok }
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :description, :address_line1, :address_line2, :city, :zip, :state, :country, :contact_name, :contact_phone, :contact_mobile, :url_web, :url_twitter, :url_facebook)
  end

end