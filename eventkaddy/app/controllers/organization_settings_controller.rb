class OrganizationSettingsController < ApplicationController
	layout 'subevent_2013'
	load_and_authorize_resource

	before_action :set_event
	before_action :set_organization_setting
	
	def new_subscribe_unsubscribe_settings
	end

	def create_subscribe_unsubscribe_settings
		if OrganizationSetting.can_be_fields? (params[:organization_setting][:fields])
			@organization_setting.fields = params[:organization_setting][:fields].as_json
		end

		@organization_setting.event_id = @event.id
		@organization_setting.save

		subcribe_page_header_image_id = setting_params[:subcribe_page_header_image_id]
		unsubcribe_page_header_image_id = setting_params[:unsubcribe_page_header_image_id]

		if subcribe_page_header_image_id.present?
			OrganizationFile.upload_member_page_banner(subcribe_page_header_image_id, @organization, @event.id, @organization_setting, :subcribe_page_header_image_id)
		end
		if unsubcribe_page_header_image_id.present?
			OrganizationFile.upload_member_page_banner(unsubcribe_page_header_image_id, @organization, @event.id, @organization_setting, :unsubcribe_page_header_image_id)
		end

		redirect_to '/organization_settings/upload_subscribe_unsubscribe_settings'
	end

	private

	def setting_params
		params.require(:organization_setting).permit(:organization_id, :setting_type_id, :subcribe_page_header_image_id, :unsubcribe_page_header_image_id, fields: {})
	end

	def set_event
		@event = Event.find_by_id(session[:event_id])
	end

	def set_organization_setting
		@organization = @event.organization
		setting_type = SettingType.find_by_name('organization_members_settings')
		@organization_setting = OrganizationSetting.find_or_initialize_by(organization: @organization, setting_type: setting_type)
	end

end