class OrganizationSetting < ApplicationRecord
	belongs_to :organization
	belongs_to :setting_type
	serialize  :json, JSON

	@@member_settings_props = [
		:event_id, # for fetching cloud storage id and event related setting
		:subcribe_page_header_image_id, #organization_file record id
		:unsubcribe_page_header_image_id, #organization_file record id
		:fields, #store json of form fields with label as key and type as value
	]

	@@json_props = @@member_settings_props

	def self.serialized_attr_accessor props
		props.each do |method_name|
			eval "
				def #{method_name}
					(self.json || {})['#{method_name}']
				end
				def #{method_name}=(value)
					self.json ||= {}
					self.json['#{method_name}'] = value
				end
			"
		end
	end

	serialized_attr_accessor @@json_props

	def self.can_be_fields? check_value
		begin
			JSON.parse(check_value.to_json)
			true
		rescue StandardError => e
			false
		end
	end
end