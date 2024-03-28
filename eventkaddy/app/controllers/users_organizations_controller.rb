class UsersOrganizationsController < ApplicationController
  load_and_authorize_resource
  
  # GET /users_organizations
  # GET /users_organizations.xml
  def index
    @users_organizations = UsersOrganization.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users_organizations }
    end
  end

  # GET /users_organizations/1
  # GET /users_organizations/1.xml
  def show
    @users_organization = UsersOrganization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @users_organization }
    end
  end

  # GET /users_organizations/new
  # GET /users_organizations/new.xml
  def new
    @users_organization = UsersOrganization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @users_organization }
    end
  end

  # GET /users_organizations/1/edit
  def edit
    @users_organization = UsersOrganization.find(params[:id])
  end

  # POST /users_organizations
  # POST /users_organizations.xml
  def create
    @users_organization = UsersOrganization.new(users_organization_params)

    respond_to do |format|
      if @users_organization.save
        format.html { redirect_to(@users_organization, :notice => 'Users organization was successfully created.') }
        format.xml  { render :xml => @users_organization, :status => :created, :location => @users_organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @users_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users_organizations/1
  # PUT /users_organizations/1.xml
  def update
    @users_organization = UsersOrganization.find(params[:id])

    respond_to do |format|
      if @users_organization.update!(users_organization_params)
        format.html { redirect_to(@users_organization, :notice => 'Users organization was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @users_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users_organizations/1
  # DELETE /users_organizations/1.xml
  def destroy
    @users_organization = UsersOrganization.find(params[:id])
    @users_organization.destroy

    respond_to do |format|
      format.html { redirect_to(users_organizations_url) }
      format.xml  { head :ok }
    end
  end

  private

  def users_organization_params
    params.require(:users_organization).permit(:user_id, :org_id)
  end

end