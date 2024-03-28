class MembersController < ApplicationController
  before_action :set_organization, only: [:for_organization_subscribe, :create, :for_organization_unsubscibe]
  before_action :set_organization_setting, only: [:for_organization_subscribe, :create, :for_organization_unsubscibe]
  layout 'member'
  load_and_authorize_resource

  def new
    @member = User.new
    @all_organization = Organization.all
  end

  def for_organization_subscribe
    @member = User.new
  end

  def create
    @member = User.new(member_params.except("organization_ids"))
    member_role = Role.find_by_name('Member').id
    @member.role_ids = [member_role]

    if @organization.blank?
      @all_organization = Organization.all
      render :new, notice: "Please select any organization"
    end

    json = {is_subscribed: true}
    @extra_fields.each do |key, value|
      default = value == 'checkbox' ? false : ''
      json[key] = params[:user][key] || default
    end

    already_member = User.find_by_email(member_params[:email])

    if already_member.present?
      already_member.json = json
      already_member.save

      UsersOrganization.find_or_create_by(user: already_member, organization: @organization)
      UsersRole.find_or_create_by(user_id: already_member.id, role_id: member_role)

      redirect_to "/members/#{@organization.id}/subscribe", notice: "#{already_member.email} registered successfully, Please Log In To browse through Organization feeds"
    elsif @member.save
      @member.json = json
      @member.save

      UsersOrganization.create(user: @member, organization: @organization)
      redirect_to "/members/#{@organization.id}/subscribe", notice: "#{@member.email} registered successfully, Please Log In To browse through Organization feeds"
    else
      render :for_organization_subscribe, organization_id: @organization.id
    end
  end

  def show
    @member = Member.find_by(id: params[:member_id])
  end

  def show_event
    @event = Event.find_by(id: params[:event_id])
    @org   = @event.organization 
    @attendee = Attendee.find_by(event_id: @event.id, email: current_user.email)
  end

  def unsubscribe
  end

  def for_organization_unsubscibe
  end

  def submit_unsubscribe
    member = User.joins(:roles).where(roles: {name: 'Member'}).where(email: member_params["email"]).where("json LIKE '%?%'", true).first

    if member
      member.is_subscribed = false
      member.save
      render :json => {message: 'Member Unsubscribed' }
    else
      render :json => {message: 'No Subcribed Member Found with this email'}
    end
  end

  def upload_members
    @event = Event.find(session[:event_id])
    @organization = @event.organization
    #create directory structure if necessary
    uploaded_io = params[:file]
    dirname = File.dirname(Rails.root.join('public','organization_data', @organization.id.to_s,'import_data',uploaded_io.original_filename))
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    #upload the session data ODS file

    File.open(Rails.root.join('public', 'organization_data', @organization.id.to_s,'import_data',uploaded_io.original_filename ), 'wb',0777) do |file|
      file.write(uploaded_io.read)
    end
    #import attendee data spreadsheet into the database
    ods_attendee_path   = Rails.root.join('public', 'organization_data', @organization.id.to_s,'import_data',uploaded_io.original_filename)
    member_import_cmd = Rails.root.join('ek_scripts','config_page_scripts',"import-members-mysql2-matched.rb \"#{session[:event_id]}\" \"#{ods_attendee_path}\" \"#{params[:job_id]}\" \"#{current_user.id}\" \"#{@organization.id}\"")

    puts "ODS/XLS PATH #{ods_attendee_path}"
    puts "attendee CMD #{member_import_cmd}"

    pid = Process.spawn("ROO_TMP='/tmp' ruby #{member_import_cmd} 2>&1")
    Rails::logger.debug "\n--------- import script output ---------\n\n #{pid} \n------------------- \n"
    Job.find(params[:job_id]).update!(pid:pid)

    Process.detach pid

    respond_to do |format|
      format.js   { render :upload_members }
      format.html { redirect_to("/events/configure/#{@event.id}", :notice => 'File was successfully imported.') }
    end

  end

  def attendee_register
    @event_id       = params[:event_id].to_i
    @event          = Event.find params[:event_id]
    @organization   = @event.organization
    @attendee       = Attendee.find_or_initialize_by(event_id: @event_id, first_name: current_user.first_name, last_name: current_user.last_name, title: current_user.title, email: current_user.email)
    @settings       = Setting.return_cached_settings_for_registration_portal({ event_id: params[:event_id] })
  end


  def attendee_register_submit
    attendee_present = Attendee.find_by(event_id: attendee_params[:event_id], email: attendee_params[:email])
    if attendee_present
      redirect_to "/members/attendee_register/#{attendee_params[:event_id]}"
    end

    @attendee = Attendee.new(attendee_params)
    if @attendee.save
      redirect_to "/", notice: "Registered As Attendee for #{@attendee.event.name}"
    else
      render :attendee_register
    end
  end

  private

  def member_params
    params.require(:user).permit(:organization_ids, :first_name, :last_name, :email, :title, :password, :password_confirmation)
  end


  def attendee_params
    params.require(:attendee).permit(:event_id, :email, :username, :first_name, :last_name, :honor_prefix, :honor_suffix, :title, :company, :biography, :business_unit, :business_phone,
     :mobile_phone, :country, :state, :city, :notes_email, :notes_email_pending, :temp_photo_filename, :photo_filename, :photo_event_file_id, 
     :iattend_sessions, :assignment, :validar_url, :publish, :twitter_url, :facebook_url, :linked_in, :username, :attendee_type_id, 
     :messaging_opt_out, :messaging_notifications_opt_out, :app_listing_opt_out, :game_opt_out, :first_run_toggle, :video_portal_first_run_toggle, 
     :custom_filter_1, :custom_filter_2, :custom_filter_3, :pn_filters, :token, :tags_safeguard, :speaker_biography, :custom_fields_1, :survey_results, 
     :travel_info, :table_assignment, :custom_fields_2, :custom_fields_3, :password)
  end

  def set_organization
    if params[:organization_id]
      @organization = Organization.find_by(id: params[:organization_id])
    else
      @organization = Organization.find_by(id: member_params["organization_ids"])
    end
  end

  def set_organization_setting
    @organization_setting = OrganizationSetting.joins(:setting_type).where(setting_type: {name: "organization_members_settings"}).where(organization: @organization).first
    @extra_fields = @organization_setting.fields if @organization_setting.present?
    @event = Event.find_by_id @organization_setting.event_id if @organization_setting 
  end

end
