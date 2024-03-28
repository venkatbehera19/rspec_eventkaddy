class EventMap < ApplicationRecord

	belongs_to :event
	belongs_to :map_type
	belongs_to :event_file, :foreign_key => 'map_event_file_id'
	has_many :location_mappings, :foreign_key => 'map_id', :dependent => :nullify

	def update_image(image_file)
    event_file_type_id = EventFileType.where(name:'map').first.id
    event_file = map_event_file_id ? EventFile.find(map_event_file_id)
                                   : EventFile.new(event_id:event_id,event_file_type_id:event_file_type_id)
    target_path = Rails.root.join('public', 'event_data', event_id.to_s, 'maps').to_path
		new_filename = "#{image_file.original_filename}"
		cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    UploadEventFileImage.new(event_file: event_file, image: image_file, target_path: target_path,
			new_filename: new_filename, event_file_owner: self, event_file_assoc_column: :map_event_file_id,
			cloud_storage_type:cloud_storage_type
			).call

		{status: true, message: 'Successfully updated event map image.'}
  end

	def interactive_map?
		MapType.where(map_type:'Interactive Map').first.id == map_type_id
	end

	def sync_interactive_map(originally_interactive)
		if interactive_map? && event_file
      if EventMap.where(event_id:event_id, map_type_id:4).length > 1
        update! map_type_id:3
        return {status: false, message: "You already have an interactive map for this event. Please update the older one if you would like to make this the new interactive map."}
      end
      update_interactive_map Rails.root.join("public#{event_file.path}")
		elsif originally_interactive
			remove_interactive_map
    else
      {status: true, message: ""}
		end
	end

	def update_interactive_map(image_path)
		map = InteractiveMap::Map.new image_path:image_path, event_id:event_id
		InteractiveMap::Configuration.new.update event_id, map.width, map.height unless map.errors.length > 0
		map.write_images unless map.errors.length > 0
		raise map.errors.join(', ') if map.errors.length > 0
		{status: true, message: 'Created related interactive map files.'}
	rescue => e
		{status: false, message: e.message}
  end

	def remove_interactive_map
		InteractiveMap::Configuration.new.remove event_id
		{status: true, message: 'Successfully turned off interactive map for this event.'}
	rescue => e
		{status: false, message: e.message}
	end
end
