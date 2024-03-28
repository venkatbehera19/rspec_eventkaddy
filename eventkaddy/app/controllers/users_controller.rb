class UsersController < ApplicationController
  # include HabtmCheckboxes
#class UsersController < Devise::SessionsController
  layout :set_layout
#  layout 'application_2013'

  before_action :get_user, :only => [:index,:new,:edit]
  before_action :accessible_roles, :only => [:new, :edit, :show, :update, :create, :user_event_role]
  before_action :verify_as_admin, :only => [:impersonate]
  load_and_authorize_resource :only => [:show,:new,:destroy,:edit,:update,:index, :user_event_role]
  # helper_method :habtm_checkboxes

  # IDEM poor man's single sign on. Don't let any other event do this or even
  # allow it for a non-exhibitor user.
  def remote_sign_in
    user = User.where(email: params[:email]).first
    status = {
      user_found:                     !!user,
      user_allowed_to_remote_sign_in: user && user.allowed_to_remote_sign_in?,
      correct_key:                    IDEM_REMOTE_SIGN_IN_KEY == params[:key],
      correct_password:               user && user.valid_password?( params[:password] )
    }
    if !status.values.include? false
      sign_in user
      redirect_to '/'
    else
      File.open("./log/remote_sign_in_log.log", "a+", 0777) {|file|
        file.puts "#{status.inspect}\nid: #{user && user.id}\n"
      }
      render :text => "Invalid.\n#{status.inspect}"
    end
  end
 # Get roles accessible by the current user
  #----------------------------------------------------
  def accessible_roles
    @accessible_roles = Role.accessible_by(current_ability,:read)
  end

  # Make the current user object available to views
  #----------------------------------------
  def get_user
    @current_user = current_user
  end

  # GET /users
  # GET /users.xml
  # GET /users.json                                       HTML and AJAX
  #-----------------------------------------------------------------------
  def index
    # @users = User.accessible_by(current_ability, :index)
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @users }
        #format.json { render :json => @sessions.to_json, :callback => params[:callback] }
        format.json { render json: UsersDatatable.new(view_context,current_ability, current_user) }
      end
  end

  # GET /users/new
  # GET /users/new.xml
  # GET /users/new.json                                    HTML AND AJAX
  #-------------------------------------------------------------------
  def new
    respond_to do |format|
      format.json { render :json => @user }
      format.xml  { render :xml => @user }
      format.html
    end
  end

  #-----------------------------------------------------------------------
  def new_install

    @user= User.select('*')
    if (@user.size==0) then

    	@user = User.new
    	respond_to do |format|
      		format.html { render :new_install, :layout => 'application' }
		end
    else
    	respond_to do |format|
      		format.html { redirect_to('/home/index') }
    	end
    end

  end


  # GET /users/1
  # GET /users/1.xml
  # GET /users/1.json                                     HTML AND AJAX
  #-------------------------------------------------------------------
  def show
    respond_to do |format|
      format.json { render :json => @user }
      format.xml  { render :xml => @user }
      format.html
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:json, :xml, :html)
  end

  # GET /users/1/edit
  # GET /users/1/edit.xml
  # GET /users/1/edit.json                                HTML AND AJAX
  #-------------------------------------------------------------------
  def edit
    respond_to do |format|
      format.json { render :json => @user }
      format.xml  { render :xml => @user }
      format.html
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:json, :xml, :html)
  end


  # POST /users
  # POST /users.xml
  # POST /users.json                                      HTML AND AJAX
  #-----------------------------------------------------------------
  def create
    @user = User.new(user_params)
    puts SUPER_ADMIN_ROLE_ID
    if params[:user][:role_ids].first.to_i.in? ([::SUPER_ADMIN_ROLE_ID, ::CLIENT_ROLE_ID])
      @user.skip_password_validation    = true
      @user.enable_confirmations        = true
      user_params[:with_two_factor] == "0" ? @user.with_two_factor=false : @user.with_two_factor=true
    end

    if @user.save
      ## this is apparently handled by some magic, but I don't know where.
      # params[:role_ids].each {|id|
      #   UsersRole.where(user_id:@user.id,_id:id).first_or_create}

      # UserMailer.invitation_confirmation(@user).deliver_now if params[:user][:role_ids].first.to_i.in? ([1, 2])

      if params[:event_ids].present?
        params[:event_ids].each do |id|
          UsersEvent.where(user_id:@user.id,event_id:id).first_or_create
        end
      end

      respond_to do |format|
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { redirect_to :action => :index }
      end
    else
      respond_to do |format|
        format.json { render :text => "Could not create user", :status => :unprocessable_entity } # placeholder
        format.xml  { head :ok }
        format.html { render :action => :new, :status => :unprocessable_entity }
      end
    end
  end

  def create_user_role 
    @user = User.new(user_params)

    if @user.save

      # binding.pry
      if user_params[:event_ids].present?
        user_params[:event_ids].split(',').each do |id|
          UsersEvent.where(user_id:@user.id,event_id:id).first_or_create
        end
      end
      respond_to do |format|
        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { redirect_to show_user_event_role_user_path(@user) }
      end
    else
      respond_to do |format|
        format.json { render :text => "Could not create user", :status => :unprocessable_entity } # placeholder
        format.xml  { head :ok }
        format.html { render :action => :user_event_role, :status => :unprocessable_entity }
      end
    end
    
  end

  def show_user_event_role 
    @user = User.find params[:id]
    @user_events = UsersEvent.where(user_id: @user.id)
   
    @result = {}
    @user_events.each do |user_event|
      @result["#{user_event.id}"] = user_event.user_event_roles.pluck(:role_id)
    end
    accessible_roles = Role.accessible_by(current_ability,:read)
    roles = accessible_roles.map do |role|
      { id: role.id, name: role.name }
    end
    @result = @result.to_json
    @roles = roles.to_json
  end

  def add_user_event
    user = User.find params[:id]
    if user.present?
      if user_params[:event_ids].present?
        user_params[:event_ids].split(',').each do |id|
          UsersEvent.where(user_id: user.id, event_id:id).first_or_create
        end
        respond_to do |format|
          format.html { redirect_to show_user_event_role_user_path(user) }
        end
      else
        respond_to do |format|
          format.html { redirect_to show_user_event_role_user_path(user), :alert => "Something went wrong." }
        end
      end
    end
    # binding.pry
  end

  #-----------------------------------------------------------------
  def create_new_install
    @user = User.new(user_params)

    @existing_users= User.select('*')
    if (@existing_users.size==0) then #if this is a brand new db install

	    if @user.save
	      respond_to do |format|
	        format.json { render :json => @user.to_json, :status => 200 }
	        format.xml  { head :ok }
	        format.html { redirect_to '/home/index' }
	      end
	    else
	      respond_to do |format|
	        format.json { render :text => "Could not create user", :status => :unprocessable_entity } # placeholder
	        format.xml  { head :ok }
	        format.html { render :action => :new, :status => :unprocessable_entity }
	      end
	    end

	 else
		format.html { redirect_to '/home/index' }
	 end

  end

  #GET
  def new_speaker_portal_user # from very first commit; does not appear to be in use

    @user = User.new
    @speaker = Speaker.find(params[:speaker_id])
    if (@speaker.email!=nil); @user.email=@speaker.email end

    respond_to do |format|

      format.html { render :action => 'new_speaker_portal_user'}
    end

  end

  #POST
  #add user account to speaker portal
  def create_speaker_portal_user # also from very first commit; not in use

    users = User.select('users.id').joins('
      LEFT JOIN users_roles ON users_roles.user_id=users.id
      LEFT JOIN roles ON users_roles.role_id=roles.id').where('users.email=? AND roles.name= ?',params[:user][:email],'Speaker')

    if (users.length == 0) then
      @user = User.new(user_params)
    else
      @user = User.find(users.first.id)
    end

    @speaker = Speaker.find(params[:speaker_id])

    if ( @user.grantSpeakerPortalAccess(session[:event_id],params) ) then

      respond_to do |format|
        format.html { redirect_to("/speakers/#{params[:speaker_id]}", :notice => 'Speaker Portal data update successful.') }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new_speaker_portal_user', :layout => 'subevent_2013', :status => :unprocessable_entity }
      end
    end
  end



    # PUT /users/1
  # PUT /users/1.xml
  # PUT /users/1.json                                            HTML AND AJAX
  #----------------------------------------------------------------------------
  def update
    if params[:user][:password].blank?
      [:password,:password_confirmation].collect{|p| params[:user].delete(p) }
    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:current_password])
    end

    respond_to do |format|
      if @user.errors[:base].empty? and @user.update!(user_params)
        event_ids        = params[:event_ids] || []
        revoke_event_ids = params[:revoke_event_ids] || []
        event_ids
          .reject {|event_id| revoke_event_ids.include? event_id }
          .each {|id| 
            UsersEvent.where(user_id:@user.id, event_id:id).first_or_create 
          }

        UsersEvent.where(user_id:@user.id, event_id:revoke_event_ids).destroy_all

        org_ids        = params[:org_ids] || []
        revoke_org_ids = params[:revoke_orgs_ids] || []
        org_ids
          .reject {|org_id| revoke_org_ids.include? org_id }
          .each {|id| 
            UsersOrganization.where(user_id: @user.id, org_id:id).first_or_create 
          }

        UsersOrganization.where(user_id:@user.id, org_id:revoke_org_ids).destroy_all  


        flash[:notice] = "Your account has been updated"
        # sign_in(@user, bypass:true) # this interferes with a super admin editing a user's account; if it is needed somewhere else, do a check on role and only run if the user is not a super admin

        format.json { render :json => @user.to_json, :status => 200 }
        format.xml  { head :ok }
        format.html { render :action => :show }
      else
        format.json { render :text => "Could not update user", :status => :unprocessable_entity } #placeholder
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.html { render :action => :edit, :status => :unprocessable_entity }
      end
  	end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:js, :xml, :html)
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json                                  HTML AND AJAX
  #-------------------------------------------------------------------

  def deactivate
    @user = User.find(params[:id])
    @user.deactivate_user
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end

    rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:json, :xml, :html)
  end

  def reactivate
    @user = User.find(params[:id])
    @user.activate_user
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end

    rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:json, :xml, :html)
  end

  def destroy

    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }

    end

    rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:json, :xml, :html)
  end

  def impersonate
    user = User.find(params[:id])
    raise "You can not impersonate as another Super Admin." if user.role? 'SuperAdmin'
    impersonate_user(user)
    redirect_to root_url
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_url
  end

  # def profile
  #   render 'users/profile/profile'
  # end
  def user_event_role 
    @user = User.new
    respond_to do |format|
      format.json { render :json => @user }
      format.xml  { render :xml => @user }
      format.html
    end
  end

  private

  def set_layout
    if current_user.role? :trackowner then
      'trackownerportal'
    else
      'superadmin_2013'
      # application_2013
      # subevent_2013
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :event_ids, :with_two_factor,{:role_ids => []}, :org_ids )
  end

  def verify_as_admin
    raise "Your not authorized for this action" unless current_user.role? 'SuperAdmin'
  end

end
