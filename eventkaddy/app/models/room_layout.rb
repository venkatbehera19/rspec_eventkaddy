class RoomLayout < ApplicationRecord

	include Magick
  	include ActiveModel::ForbiddenAttributesProtection

	belongs_to :room_layout_configuration
	belongs_to :event
	belongs_to :event_file, :optional => true
	belongs_to :location_mapping, :optional => true

	has_many :sessions, :through => :sessions_room_layouts

	# s3 updated
	def updateImage(params)

		if (params[:room_layout_file]!=nil) then #update/add photo

			uploaded_io = params[:room_layout_file]
			file_extension = File.extname uploaded_io.original_filename
			new_filename = "#{self.title.gsub(/\s/,'').gsub(/\W/,'_')}_room_layout_#{Time.now().strftime('%Y%m%d%H%M%S')}#{file_extension}"
			event_file_type_id 			= EventFileType.where(name:"room_layout").first.id
			target_path 						= Rails.root.join('public','event_data', self.event_id.to_s,'room_layouts').to_path
			cloud_storage_type_id   = Event.find(self.event_id).cloud_storage_type_id
			cloud_storage_type      = nil
			unless cloud_storage_type_id.blank?
				cloud_storage_type 		= CloudStorageType.find(cloud_storage_type_id)
			end

			if (self.event_file==nil) then
				self.event_file = EventFile.create(event_id: self.event_id, event_file_type_id:event_file_type_id)
			end	

			UploadEventFileImage.new(
				event_file:              self.event_file,
				image:                   uploaded_io,
				target_path:             target_path,
				new_filename:            new_filename,
				event_file_owner: 			 self,
				event_file_assoc_column: :event_file_id,
				new_height:              600,
				new_width:               600,
				cloud_storage_type:      cloud_storage_type
			).call
		end

	end

	#adjust session-room_layout associations to reflect the default toggle status
	def updateDefault(params)

		puts "params check #{params}"

		if (params[:room_layout][:default]=="1") then

			#remove default status from all layouts tied to the same location mapping
			room_layouts = RoomLayout.where("event_id= ? AND location_mapping_id= ? AND `default`= ? AND id!= ?",
				self.event_id,self.location_mapping_id,true,self.id)
			
			room_layouts.each do |room_layout|
				
				room_layout.update!(default:false)
				#remove association between session and prior default room layouts 
				room_layout.location_mapping.sessions.each do |session|
					SessionsRoomLayout.where(session_id:session.id,room_layout_id:room_layout.id).destroy_all
				end			
			end
			
			self.location_mapping.sessions.each do |session|

				session_room_layout = SessionsRoomLayout.where(room_layout_id:self.id,session_id:session.id,event_id:self.event_id).first_or_initialize
				session_room_layout.save() #update!(default:1)
			end
		
		end


	end



end
