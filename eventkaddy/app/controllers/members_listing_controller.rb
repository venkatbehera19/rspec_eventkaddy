class MembersListingController < ApplicationController
  layout 'subevent_2013'
  before_action :check_user

  def index
    @event = Event.find_by_id(session["event_id"])
    @organization = @event.organization
    @members = @organization.users.joins(:roles).where(roles: {name: "Member"})
    @organization_setting = OrganizationSetting.joins(:setting_type).where(setting_type: {name: "organization_members_settings"}).where(organization: @organization).first
  end

  def organization_email_queue
    @event = Event.find_by_id(session["event_id"])
    @organization = @event.organization
    @email_queues = OrganizationEmailsQueue.where(organization: @organization)
  end

  def show_email
    @email_queue = OrganizationEmailsQueue.find(params[:id])
    if @email_queue.blank?
      redirect_to '/members_listing/organization_email_queue', notice: "Something went wrong."
    end
    @template    = OrganizationEmailTemplate.find @email_queue.organization_email_template_id
  end

  def destroy_email
    @email_queue = OrganizationEmailsQueue.find(params[:id])
    @email_queue.destroy

    respond_to do |format|
      format.html { redirect_to("/members_listing/organization_email_queue") }
    end
  end

  def create_member_by_client
    @member = User.new(member_params.except("organization_ids"))
    member_role = Role.find_by_name('Member').id
    @member.role_ids = [member_role]
    event = Event.find_by_id(session["event_id"])
    organization = event.organization
    
    organization_setting = OrganizationSetting.joins(:setting_type).where(setting_type: {name: "organization_members_settings"}).where(organization: organization).first
    extra_fields = []
    extra_fields = organization_setting.fields if organization_setting.present?
    json = {is_subscribed: true}
    extra_fields.each do |key, value|
      default = value == 'checkbox' ? false : ''
      json[key] = params[:user][key] || default
    end

    @member.password = SecureRandom.hex(4)
    @member.json = json

    already_member = User.find_by(email: member_params[:email])

    if already_member
      already_member.json = json
      already_member.save

      UsersOrganization.find_or_create_by(user: already_member, organization: organization)
      UsersRole.find_or_create_by(user_id: already_member.id, role_id: member_role)
      render json: {status: "200", message: 'User added as Member', member: already_member}
    elsif @member.save
      UsersOrganization.create(user: @member, organization: organization)
      render json: {status: "200", message: 'Member Created', member: @member}
    else
      render json: {status: :unprocessable_entity, message: @member.errors.full_messages}
    end

  end

  def send_reset_password_mail
    user = User.find_by(id: params[:user_id])
    if user
      User.send_reset_password_instructions({email: user.email})
      render json: {message: "Password Reset Mail Sent"}
    else
      render json: {message: "Member Not Found"}
    end
  end

  private

  def check_user
    unless current_user && (current_user.role?(:client) || (current_user.role?(:super_admin)))
      redirect_to root_url
    else
      true
    end
  end

  def member_params
    params.require(:user).permit(:organization_ids, :first_name, :last_name, :email, :title)
  end
end
