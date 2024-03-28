class OrganizationFile < ApplicationRecord
	require 'RMagick'
	include Magick

	include ActiveModel::ForbiddenAttributesProtection

	belongs_to :event_file_type
	belongs_to :cloud_storage_type, :optional => true
	belongs_to :organization

	def self.upload_email_image params, organization, event_id
    if (params[:event_file]!=nil)
			uploaded_io             = params[:event_file]
			event_file_type_id      = EventFileType.where(name:"email_template_image").first.id
			filename                = uploaded_io.original_filename
			file_extension          = File.extname uploaded_io.original_filename
			org_file                = self.new(organization: organization, event_file_type_id: event_file_type_id)
			target_path 		    = Rails.root.join('public','organization_data', organization.id.to_s,'organization_email_file').to_path
			cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
			end

			UploadEventFileImage.new(
				event_file:              org_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            filename,
				cloud_storage_type:      cloud_storage_type,
				#resize_without_write:    true, # to not write image on server
			).call
		end

		if org_file.path
			return true
		else
			return false
		end

	end


	def self.upload_member_page_banner file, organization, event_id, owner, column
		uploaded_io             = file
		event_file_type_id      = EventFileType.find_by_name("member_page_banner").id
		filename                = uploaded_io.original_filename
		file_extension          = File.extname uploaded_io.original_filename
		org_file                = self.new(organization: organization, event_file_type_id: event_file_type_id)
		target_path 		        = Rails.root.join('public','organization_data', organization.id.to_s,'organization_member_page').to_path
		cloud_storage_type_id   = Event.find(event_id).cloud_storage_type_id
		cloud_storage_type      = nil
		unless cloud_storage_type_id.blank?
			cloud_storage_type    = CloudStorageType.find(cloud_storage_type_id)
		end
		
		UploadEventFileImage.new(
			event_file:              org_file,
			image:                   uploaded_io,
			target_path:             target_path,
			new_filename:            filename,
			cloud_storage_type:      cloud_storage_type,
			#resize_without_write:    true,
			event_file_owner:        owner,
			event_file_assoc_column: column
		).call
	end




	def file_path event_id
		ReturnAWSUrl.new(event_id, self.path, true).call
	end

end