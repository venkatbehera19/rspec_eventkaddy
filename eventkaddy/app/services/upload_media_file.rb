require 'aws-sdk-s3'

class UploadMediaFile

  include Magick

  def initialize(args)
    @media_file              = args[:media_file]
    @video                   = args[:video]
    @target_path             = args[:target_path]
    @new_filename            = args[:new_filename]
    @cloud_storage_type      = args[:cloud_storage_type]
    @event_file_id           = args[:event_file_id]
  end

  def call
    upload_media_file
  end

  private

  attr_reader :media_file, :video, :target_path, :new_filename, :cloud_storage_type

  def ensure_path
    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  end

  def media_file_path
    "#{target_path.to_s.slice(target_path.to_s.index("event_data")..-1)}/#{new_filename}"
  end

  def full_path
    "#{target_path}/#{new_filename}"
  end

  def write_video
    File.open(full_path, 'wb', 0777) {|f|
      f.write(video.read)}
  end

  def magick_img
    Magick::Image::read(full_path).first
  end

  def update_media_file
    media_file.update!(name:new_filename,path:media_file_path, event_file_id: @event_file_id)
      # ,mime_type:magick_img.mime_type,size:magick_img.filesize)
  end

  def configure_and_upload_to_s3
    bucket = cloud_storage_type.bucket
    region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))
    client = Aws::S3::Client.new(region: region, access_key_id: creds['AccessKeyId'],secret_access_key: creds['SecretAccessKey'])
    client.put_object(bucket: bucket, key: media_file_path, body: video)
  end

  def upload_media_file
    if !cloud_storage_type.blank?
      #upload to s3
      configure_and_upload_to_s3; update_media_file; 
    else
      ensure_path; write_video; update_media_file; 
    end
  end

end
