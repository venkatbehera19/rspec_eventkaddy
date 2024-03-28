require 'aws-sdk-s3'

class UploadEventFile

  def initialize(args)
    @event_file              = args[:event_file]
    @file                    = args[:file]
    @target_path             = args[:target_path]
    @new_filename            = args[:new_filename]
    @event_file_owner        = args[:event_file_owner]
    @event_file_assoc_column = args[:event_file_assoc_column]
    @cloud_storage_type      = args[:cloud_storage_type]
    @skip_event_file_update  = args[:skip_event_file_update]
    @content_type            = args[:content_type]
    @public_ack              = args[:public_ack]
  end

  def call
    upload_event_file
  end

  private

  attr_reader :event_file, :file, :target_path, :new_filename, :event_file_owner, :event_file_assoc_column, :cloud_storage_type, :skip_event_file_update, :content_type, :public_ack

  def ensure_path
    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  end

  def event_file_path
    "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{new_filename}"
  end

  def full_path
    "#{target_path}/#{new_filename}"
  end

  def write_file
    File.open(full_path, 'wb', 0777) {|f|
      f.write(file.read)}
  end

  def update_event_file
    event_file.update!(name:new_filename,path:event_file_path, mime_type: content_type || file.content_type, size: file.size)
  end

  def update_s3_event_file
    event_file.update!(name:new_filename,path:event_file_path, mime_type: content_type || file.content_type, size: file.size, cloud_storage_type_id: cloud_storage_type.id)
  end

  def update_event_file_owner
    event_file_owner.update!(event_file_assoc_column => event_file.id) unless event_file_owner.blank?
    if event_file_owner && event_file_owner.respond_to?(:online_url_column) && 
        !event_file_owner.event.master_url.blank? && 
        !event_file_owner.online_url_column.blank?
      # calls update attributes; see speaker for method
      event_file_owner.online_url_column = event_file_owner.event.master_url + event_file_path 
    end
  end

  def configure_and_upload_to_s3
    bucket = cloud_storage_type.bucket
    region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))
    client = Aws::S3::Client.new(region: region, access_key_id: creds['AccessKeyId'],secret_access_key: creds['SecretAccessKey'])
    response = client.put_object(bucket: bucket, key: event_file_path, body: file, content_type: event_file.mime_type ? event_file.mime_type : "")
    if response.etag
      puts "Object '#{event_file_path}' uploaded to bucket '#{bucket}'."
    else
      puts "Object '#{event_file_path}' not uploaded to bucket '#{bucket}'."
    end
    rescue StandardError => e
      puts "Error uploading object: #{e.message}"
  end

  def configure_and_upload_to_s3_as_public
    bucket = cloud_storage_type.bucket
    region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))
    client = Aws::S3::Client.new(region: region, access_key_id: creds['AccessKeyId'],secret_access_key: creds['SecretAccessKey'])
    s3 = Aws::S3::Resource.new(client: client)
    obj = s3.bucket(bucket).object(event_file_path)
    response = obj.upload_file(full_path, acl: 'public-read', content_type: event_file.mime_type ? event_file.mime_type : "")
    if response
      puts "Object '#{event_file_path}' uploaded to bucket '#{bucket}' with public read."
    else
      puts "Object '#{event_file_path}' not uploaded to bucket '#{bucket}'."
    end
    rescue StandardError => e
      puts "Error uploading object: #{e.message}"
  end

  def upload_event_file
    if !cloud_storage_type.blank?
      #upload to s3
      if public_ack
        configure_and_upload_to_s3_as_public
      else
        configure_and_upload_to_s3
      end
      update_s3_event_file unless skip_event_file_update
      update_event_file_owner
    else
      ensure_path; write_file; update_event_file; update_event_file_owner;
    end
  end

end
