class OrganizationEmailsQueue < ApplicationRecord
	belongs_to :user
	belongs_to :organization
  belongs_to :organization_email_template
  serialize  :invitation_fields, JSON

  def self.queue_email_for_org_user_email email_params
  	# current specically for user only
    email_type_id = EmailType.find_by(name: email_params[:email_type]).id
    user          = User.find_by(id: email_params[:user_id])
    return {status: false, message: "#{model_name.titleize}, #{email_params[:model_id]} does not exist."} unless user
    invitation_fields = { "calendar_invite_filename": email_params[:calendar_invite_filename],
                          "calendar_invite_organizer": email_params[:calendar_invite_organizer],
                          "calendar_invite_desciption": email_params[:calendar_invite_desciption]}
    create(
      organization:      email_params[:organization],
      user:              user,
      email_type_id:     email_type_id,
      email:             user.email,
      sent:              false,
      status:            'pending',
      timezone:          email_params[:timezone],
      active_time:       email_params[:active_time],
      deliver_later:     email_params[:deliver_later],
      invitation_fields: invitation_fields,
      attach_calendar_invite: email_params[:attach_calendar_invite],
      calendar_invite_start:  email_params[:calendar_invite_start],
      calendar_invite_end:    email_params[:calendar_invite_end],
      organization_email_template_id:   email_params[:template_id],
    )
  end

end