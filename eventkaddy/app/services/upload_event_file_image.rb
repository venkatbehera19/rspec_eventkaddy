require 'aws-sdk-s3'

class UploadEventFileImage

  include Magick

  def initialize(args)
    @event_file              = args[:event_file]
    @event_file_owner        = args[:event_file_owner]
    @event_file_assoc_column = args[:event_file_assoc_column]
    @image                   = args[:image]
    @target_path             = args[:target_path]
    @new_filename            = args[:new_filename]
    @new_height              = args[:new_height]
    @new_width               = args[:new_width]
    @maintain_aspect_ratio   = args.fetch(:maintain_aspect_ratio, true)
    @cloud_storage_type      = args[:cloud_storage_type]
    @resize_without_write    = args[:resize_without_write]
    @upload_for_mobile_forms = args[:upload_for_mobile_forms]
    @required_image_size     = args[:required_image_size]
  end

  def call
    upload_event_file
  end

  private

  attr_reader :event_file, :event_file_owner, :event_file_assoc_column, :image, :target_path, :new_filename, :new_height, :new_width, :maintain_aspect_ratio, :cloud_storage_type, :resize_without_write, :upload_for_mobile_forms, :required_image_size

  def ensure_path
    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  end

  def event_file_path
    if target_path.to_s.include? "event_data"
      return "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{new_filename}"
    elsif target_path.to_s.include? "ce-credits"
      return "#{target_path.to_s.slice(target_path.to_s.index("/ce-credits")..-1)}/#{new_filename}"
    elsif target_path.to_s.include? "event_app_form_data"
      return "#{target_path.to_s.slice(target_path.to_s.index("/#{event_file_owner.id}")..-1)}/#{new_filename}"
    elsif target_path.to_s.include? "organization_data"
      return "#{target_path.to_s.slice(target_path.to_s.index("/organization_data")..-1)}/#{new_filename}"
    end
  end

  def full_path
    "#{target_path}/#{new_filename}"
  end

  def write_image
    File.open(full_path, 'wb', 0777) {|f|
      f.write(image.read)
    }
  end

  def magick_img
    Magick::Image::read(full_path).first
  end

  def update_event_file
    event_file.assign_attributes(name:new_filename,path:event_file_path,mime_type:magick_img.mime_type,size:magick_img.filesize)
    event_file.save!
  end

  def update_s3_event_file
    event_file.assign_attributes(name:new_filename,path:event_file_path,cloud_storage_type_id: cloud_storage_type.id)
    event_file.save!
  end

  def update_event_file_owner
    if event_file_owner && event_file_owner.respond_to?(:online_url_column) && 
        !event_file_owner.event.master_url.blank? && 
        !event_file_owner.online_url_column.blank?
      # calls update attributes; see speaker for method
      event_file_owner.assign_attributes(online_url_column: event_file_owner.event.master_url + event_file_path)
    end
    event_file_owner.update_attribute(event_file_assoc_column, event_file.id) unless event_file_owner.blank?
  end

  def resize_image
    if resize_without_write
      img = image
    else
      img = magick_img
    end
    if new_height!=nil || new_width!=nil
      img.change_geometry("#{new_width}x#{new_height}#{maintain_aspect_ratio ? '' : '!'}") {|cols, rows, image|
        image.resize!(cols,rows)}
      img.write(full_path)
      event_file.assign_attributes(mime_type:img.mime_type, size:img.filesize)
    end
  end

  def check_image_dimensions
    unless required_image_size=="#{magick_img.columns}x#{magick_img.rows}"
      File.delete(full_path) if File.exist?(full_path)
      raise "Required size is #{required_image_size}"
    end
  end

  def configure_and_upload_to_s3
    bucket = cloud_storage_type.bucket
    region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))
    client = Aws::S3::Client.new(region: region, access_key_id: creds['AccessKeyId'], secret_access_key: creds['SecretAccessKey'])
    s3 = Aws::S3::Resource.new(client: client)
    obj = s3.bucket(bucket).object(event_file_path)
    obj.upload_file(full_path, acl:'public-read') do |response|
      @etag = response.etag
    end
    # response = s3.upload_file(bucket: bucket, key: event_file_path, body: image)
    if @etag
      puts "Object '#{event_file_path}' uploaded to bucket '#{bucket}'."
      authenticated_url  = obj.presigned_url(:get, expires_in: cloud_storage_type.link_expiration_duration.to_i)
      puts authenticated_url
    else
      puts "Object '#{event_file_path}' not uploaded to bucket '#{bucket}'."
    end
    rescue StandardError => e
      puts "Error uploading object: #{e.message}"
  end


  def upload_event_file
    if event_file.blank? && !cloud_storage_type.blank?
      # for QR codes
      configure_and_upload_to_s3
      return
    end
    ensure_path
    write_image unless resize_without_write
    check_image_dimensions if (upload_for_mobile_forms && !required_image_size.blank?)
    resize_image
    if !cloud_storage_type.blank?
      configure_and_upload_to_s3; update_s3_event_file;
    else
      update_event_file; 
    end
    update_event_file_owner unless upload_for_mobile_forms
  end

end
