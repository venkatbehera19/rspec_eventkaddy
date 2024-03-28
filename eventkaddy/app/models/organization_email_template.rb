class OrganizationEmailTemplate < ApplicationRecord
	include EmailTemplateMethods
	belongs_to :template_type
	belongs_to :organization


	def self.email_password_template_for event_id, type_name
		template_type = TemplateType.find_by(name: type_name)
		organization = Event.find_by_id(event_id).organization

		find_by(organization_id: organization.id, template_type_id: template_type.id) || new(
			template_type:    template_type,
			content:          default_content( event_id, type_name),
			email_subject:    default_email_subject( event_id, type_name ),
			organization:      organization
		)
	end

	def send_mails params, event_id

		timezone_offset = ActiveSupport::TimeZone[params[:timezone]].now.formatted_offset

		if !params[:active_time].blank?
			params[:active_time] = DateTime.strptime("#{params[:active_time]} #{timezone_offset}","%m/%d/%Y %I:%M %p %:z")
		end

		if params[:calendar_invite_start].present?
			params[:calendar_invite_start] = DateTime.strptime("#{params[:calendar_invite_start]} #{timezone_offset}","%m/%d/%Y %I:%M %p %:z")
		end

		if params[:calendar_invite_end].present?
			params[:calendar_invite_end] = DateTime.strptime("#{params[:calendar_invite_end]} #{timezone_offset}","%m/%d/%Y %I:%M %p %:z")
		end

		params[:user_id].each do |recipient_id|
			email_params  = {
				organization:             self.organization,
				user_id:                  recipient_id,
				email_type:               'organization_email',
				active_time:              params[:active_time],
				deliver_later:            params[:deliver_later],
				attach_calendar_invite:   params[:attach_calendar_invite],
				calendar_invite_start:    params[:calendar_invite_start],
				calendar_invite_end:      params[:calendar_invite_end],
				template_id:              self.id,
				timezone:                 params[:timezone],
				calendar_invite_filename: params[:calendar_invite_filename],
				calendar_invite_organizer:params[:calendar_invite_organizer],
				calendar_invite_desciption:params[:calendar_invite_desciption],
			}
			result = OrganizationEmailsQueue.queue_email_for_org_user_email email_params
		end

	end

end