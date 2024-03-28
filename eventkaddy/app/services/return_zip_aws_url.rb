require 'aws-sdk-s3'

class ReturnZipAWSUrl

  def initialize(download_request)
    @event                = Event.find download_request.event_id
    unless @event.cloud_storage_type_id.blank?
      @cloud_storage_type = CloudStorageType.find(@event.cloud_storage_type_id)
    end
    @url                  = {"url" => ""}
    @file_path            = download_request.path
  end

  def call
    return_url
  end

  private
  attr_reader :download_request

  def configure_aws
    path = Rails.root.join('./config/creds').to_path
    filename = "#{@cloud_storage_type.bucket}_creds.json"
    full_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(full_path))
    Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])
    Aws.config.update({region: @cloud_storage_type.region})
  end

  def return_presigned_url
    s3   = Aws::S3::Resource.new
    item = s3.bucket(@cloud_storage_type.bucket).object(@file_path)
    authenticated_url  = item.presigned_url(:get, expires_in: @cloud_storage_type.link_expiration_duration.to_i)
    @url["url"] = authenticated_url
  end

  def return_url
    if !@cloud_storage_type.blank?
      configure_aws
      return_presigned_url
    end
  end

end
