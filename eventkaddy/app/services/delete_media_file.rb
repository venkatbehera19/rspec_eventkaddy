require 'aws-sdk-s3'

class DeleteMediaFile

  include Magick

  def initialize(args)
    @media_file              = args[:media_file]
    @video                   = args[:video]
    @target_path             = args[:target_path]
    @cloud_storage_type      = args[:cloud_storage_type]
  end

  def call
    delete_media_file
  end

  private

  attr_reader :media_file, :video, :target_path, :cloud_storage_type

  def configure_and_delete_s3_file
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
      configure_and_delete_s3_file
    else
      #do nothing 
    end
  end

end
