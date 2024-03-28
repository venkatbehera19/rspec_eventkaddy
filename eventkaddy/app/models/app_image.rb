include Magick

class AppImage < ApplicationRecord
  include ListItem
  extend ListItem
  
  # attr_accessible :app_image_type_id, :device_type_id, :event_file_id, :event_id, :app_image_size_id, :is_template, :link, :name, :parent_id, :position

  belongs_to :event
  belongs_to :event_file, :dependent => :destroy, :optional => true

  belongs_to :app_image_type, :optional => true
  belongs_to :app_image_size, :optional => true
  belongs_to :device_type, :optional => true

  def path
    if event_file.cloud_storage_type_id.blank?
      return event_file.path
    else
      return event_file.return_authenticated_url()['url']
    end
  end

  def event_file_type
    event_file.event_file_type
  end

  def hr_name
    hr_name = name.gsub(/(_.............._.png)/,''); hr_name.gsub(/(orig_)/,'');
  end

  def self.update_all_positions(app_images_array)
    app_images_array.each do |parent|
      AppImage.where(parent_id:parent.id).each {|a| a.update!(position:parent.position) }
    end
  end

  def update_position_only(json_position_data, app_images_array)
    AppImage.updatePositions(json_position_data) unless json_position_data.blank?
    AppImage.update_all_positions(app_images_array)
  end

  def self.create_app_images(event_id, source_image, image_type, link, json_position_data, app_images_array)

    directory_path      = Rails.root.join('public','event_data',event_id.to_s,'app_images',image_type)
    orig_image_filename = "orig_#{source_image.original_filename}"

    ## delete previous image
    # File.delete("#{directory_path}/#{orig_image_filename}") unless orig_image_filename.blank? || !File.exist?("#{directory_path}/#{orig_image_filename}")
    # FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)
    # File.open("#{directory_path}/#{orig_image_filename}", 'wb', 0777) { |file| file.write(source_image.read) }
    # orig_image                    = Magick::Image::read("#{directory_path}/#{orig_image_filename}").first
    
    app_image_type                = AppImageType.where(name:image_type).first

    template_app_image = AppImage.create(event_id:           event_id,
                                       parent_id:         0,
                                       is_template:       true,
                                       app_image_type_id: app_image_type.id,
                                       name:              orig_image_filename,
                                       link:              link)
    
    event_file_type_id = EventFileType.where(name:"app-image").first.id
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    cloud_storage_type = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    setImage(source_image, directory_path, orig_image_filename, event_file_type_id, template_app_image, cloud_storage_type, event_id, false)
      # template_app_image.event_file = EventFile.new(event_id:event_id, name:orig_image_filename)


    # template_app_image.save()
 
    #update position for template images
    AppImage.createAndUpdatePositions(json_position_data, template_app_image) unless json_position_data.blank?

    ## create the app images sized for each device type ##
    DeviceType.where(leaf:1).each do |device_type|

      orig_image = Magick::Image::read("#{directory_path}/#{orig_image_filename}").first

      #get necessary size, given the device type and app image type
      image_info = DeviceAppImageSize.where(device_type_id:device_type.id,app_image_type_id:app_image_type.id).first

      # raise "ERROR, NO SIZING AVAILABLE FOR DEVICE TYPE #{device_type.name}" unless image_info
      unless image_info
        puts "NO SIZING AVAILABLE FOR DEVICE TYPE #{device_type}"
        next
      end

      image_width  = image_info.app_image_size.image_width
      image_height = image_info.app_image_size.image_height

      filename = "#{device_type.name.gsub!(/\s/,'')}_#{orig_image_filename}"

      app_image = AppImage.create(event_id:          event_id,
                               parent_id:         template_app_image.id,
                               is_template:       false,
                               app_image_type_id: app_image_type.id,
                               device_type_id:    device_type.id,
                               app_image_size_id: image_info.app_image_size_id,
                               name:              filename,
                               link:              template_app_image.link, 
                               position:          template_app_image.position)

      setImage(orig_image, directory_path, filename,event_file_type_id, app_image,cloud_storage_type,event_id, true, image_width, nil, maintain_aspect_ratio:true)
    end
    unless json_position_data.blank?
      self.update_all_positions(app_images_array)
    end
  end

  def update_links(link)
    update!(link:link)
    AppImage.where(parent_id:id).each {|a| a.update!(link:link) }
  end

  def update_app_images(source_image, link, json_position_data, app_images_array)

    directory_path      = Rails.root.join('public','event_data',event_id.to_s,'app_images',self.app_image_type.name)
    orig_image_filename = "orig_#{source_image.original_filename}"

    ## delete previous image
    File.delete("#{directory_path}/#{orig_image_filename}") unless orig_image_filename.blank? || !File.exist?("#{directory_path}/#{orig_image_filename}")
    FileUtils.mkdir_p(directory_path) unless File.directory?(directory_path)

    File.open("#{directory_path}/#{orig_image_filename}", 'wb', 0777) { |file| file.write(source_image.read) }


    orig_image                    = Magick::Image::read("#{directory_path}/#{orig_image_filename}").first
    app_image_type                = self.app_image_type

    self.update_columns(name:orig_image_filename, link:link)

    self.event_file.update_column(name:orig_image_filename)
    event_file_type_id = EventFileType.where(name:"app-image").first.id
    cloud_storage_type_id = Event.find(event_id).cloud_storage_type_id
    cloud_storage_type = nil
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    setImage(source_image, directory_path, orig_image_filename, event_file_type_id, self, cloud_storage_type, event_id, false)

    self.save()

    AppImage.where(parent_id:id).destroy_all

    #update position for template images
    AppImage.updatePositions(json_position_data) unless json_position_data.blank?
    ## create the app images sized for each device type ##
    DeviceType.where(leaf:1).each do |device_type|

      orig_image = Magick::Image::read("#{directory_path}/#{orig_image_filename}").first

      #get necessary size, given the device type and app image type
      image_info = DeviceAppImageSize.where(device_type_id:device_type.id,app_image_type_id:app_image_type.id).first

      unless image_info
        puts "NO SIZING AVAILABLE FOR DEVICE TYPE #{device_type}"
        next
        # raise "image_info not found. Tried to find image size for device [id:#{device_type.id} name:#{device_type.name}] and app image type [id:#{app_image_type.id} name:#{app_image_type.name}]"
      end

      # puts "ERROR, NO SIZING AVAILABLE FOR DEVICE TYPE #{device_type}"; next; if image_info==nil

      image_width  = image_info.app_image_size.image_width
      image_height = image_info.app_image_size.image_height

      filename = "#{device_type.name.gsub!(/\s/,'')}_#{source_image.original_filename}"

      app_image = AppImage.new(event_id:          event_id,
                               parent_id:         self.id,
                               is_template:       false,
                               app_image_type_id: app_image_type.id,
                               device_type_id:    device_type.id,
                               app_image_size_id: image_info.app_image_size_id,
                               name:              filename,
                               link:              self.link)

      app_image.event_file = EventFile.new(event_id:event_id, name:filename)
      setImage(orig_image, directory_path, filename,event_file_type_id, app_image,cloud_storage_type,event_id, true, image_width, nil, maintain_aspect_ratio:true)
      app_image.save()
    end
    unless json_position_data.blank?
      self.update_all_positions(app_images_array)
    end
  end

  # s3 updated
  def self.setImage(image_file, directory_path, new_filename, event_file_type_id, event_file_owner, cloud_storage_type, event_id, resize_without_write, resize_width = nil, resize_height = nil, options = {})
    
    if image_file!=nil
      
      File.delete("#{directory_path}/#{new_filename}") unless new_filename.blank? || !File.exist?("#{directory_path}/#{new_filename}")
      new_filename.gsub!(/(^.+)(\..+)/,"\\1_#{Time.now().strftime('%Y%m%d%H%M%S')}_\\2")

      # if resize_width!=nil || resize_height!=nil
      #   maintain_aspect_ratio = options.fetch(:maintain_aspect_ratio, true)
      #   maintain_aspect_ratio ? aspect_ratio = nil : aspect_ratio = "!"
      #   image_file.change_geometry("#{resize_width}x#{resize_height}#{aspect_ratio}") { |cols, rows, img| img.resize!(cols,rows) }
      # end
      event_file = EventFile.new(event_id:event_id, event_file_type_id:event_file_type_id)
      UploadEventFileImage.new(
        event_file:              event_file,
        image:                   image_file,
        target_path:             directory_path,
        new_filename:            new_filename,
        event_file_owner:        event_file_owner,
        event_file_assoc_column: :event_file_id,
        new_height:              resize_width,
        new_width:               resize_height,
        resize_without_write:    resize_without_write,
        cloud_storage_type:      cloud_storage_type
      ).call  
    end
  end

  def remove_original_and_copies
    AppImage.where(parent_id:id).destroy_all
    self.destroy
  end

end
