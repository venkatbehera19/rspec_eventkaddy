## Uses UploadEventFileImage to upload images for many files, instead of one.

class BulkUploadEventFileImage

  attr_reader :event, :event_file_type_id, :files, :owner_class, :owner_assoc, :owner_identifier, :target_path, :rename_image, :use_extension_in_identifier, :new_height, :new_width

  def initialize(args)
    @event                       = args[:event]
    @event_file_type_id          = args[:event_file_type_id]
    @files                       = args[:files]
    @owner_class                 = args[:owner_class]
    @owner_assoc                 = args[:owner_assoc]
    @owner_identifier            = args[:owner_identifier]
    @target_path                 = args[:target_path]
    @rename_image                = args.fetch(:rename_image, true)
    @use_extension_in_identifier = args.fetch(:use_extension_in_identifier, false)
    @new_height                  = args.fetch(:new_height, false)
    @new_width                   = args.fetch(:new_width, false)
  end

  def call
    update_images
  end

  private

  def filename(image_file)
    if rename_image
      "#{without_extension(image_file)}#{Time.now.strftime('%Y%m%d%H%M%S')}#{extension(image_file)}"
    else
      image_file.original_filename
    end
  end

  def create_and_associate_event_file(efo)
    f = EventFile.create event_id:event.id, event_file_type_id:event_file_type_id
    efo.update! owner_assoc => f.id
    f
  end

  def event_file(efo)
    ef = EventFile.where id: efo.send(owner_assoc)
    ef.length > 0 ? ef[0] : create_and_associate_event_file(efo)
  end

  def without_extension(image_file)
    File.basename image_file.original_filename, extension(image_file)
  end

  def extension(image_file)
    File.extname image_file.original_filename
  end

  def owner_identifier_value(image_file)
    use_extension_in_identifier ? image_file.original_filename : without_extension(image_file)
  end

  def event_file_owner(image_file)
    owner_class.where :event_id => event.id, owner_identifier => owner_identifier_value(image_file)
  end

  def update_image(image_file)
    cloud_storage_type_id = Event.find(event.id).cloud_storage_type_id
    unless cloud_storage_type_id.blank?
      cloud_storage_type = CloudStorageType.find(cloud_storage_type_id)
    end
    efo = event_file_owner image_file
    if efo.length == 1
      UploadEventFileImage.new(
        event_file:              event_file(efo[0]),
        image:                   image_file,
        target_path:             target_path,
        new_filename:            filename(image_file),
        event_file_owner:        efo[0],
        event_file_assoc_column: owner_assoc,
        new_height:              new_height,
        new_width:               new_width,
        cloud_storage_type:      cloud_storage_type
      ).call
    elsif efo.length == 0
      not_found_error without_extension(image_file)
    else
      multiple_matches_error without_extension(image_file)
    end
  end

  def not_found_error(value)
    event.errors.add("Upload error: ", "#{owner_class} with #{owner_identifier} #{value} does not have a matching record in the database.")
  end

  def multiple_matches_error(value)
    event.errors.add("Upload error: ", "More than one #{owner_class} with #{owner_identifier} #{value} exists. Please remove the extra #{owner_class} and try again.")
  end

  def update_images
    files.each {|f| update_image f}
  end

end
