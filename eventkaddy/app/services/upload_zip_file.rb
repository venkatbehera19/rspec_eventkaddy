require 'aws-sdk-s3'

class UploadZipFile

  def initialize(args)
    @zip_file_path           = args[:zip_file_path]
    @target_path             = args[:target_path]
    @new_filename            = args[:new_filename]
    @cloud_storage_type      = args[:cloud_storage_type]
    @download_request        = args[:download_request]
  end

  def call
    upload_zip_file
  end

  private

  attr_reader :zip_file_path, :target_path, :new_filename, :cloud_storage_type, :download_request

  def zip_file_content
    File.read(zip_file_path)
  end

  def zip_file_path_relative
    "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{new_filename}"
  end

  def configure_and_upload_to_s3
    bucket = cloud_storage_type.bucket
    region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))

    client = Aws::S3::Client.new(
      region: region,
      access_key_id: creds['AccessKeyId'],
      secret_access_key: creds['SecretAccessKey']
    )

    response = client.put_object(
      bucket: bucket,
      key: zip_file_path_relative,
      body: zip_file_content,
      content_type: 'application/zip'
    )

    if response.etag
      download_request.update(path: zip_file_path_relative)
      puts "Object '#{zip_file_path_relative}' uploaded to bucket '#{bucket}'."
    end
  end

  def upload_zip_file
    if !cloud_storage_type.blank?
      configure_and_upload_to_s3
    end
  end

end
