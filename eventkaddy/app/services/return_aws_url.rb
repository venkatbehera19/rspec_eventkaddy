require 'aws-sdk-s3'
#type options are "video", "audio", and "subtitle"
class ReturnAWSUrl

  def initialize(event_id,file_path, public_url = false)
    @event          = Event.find(event_id)
    unless @event.cloud_storage_type_id.blank?
      @cloud_storage_type = CloudStorageType.find(@event.cloud_storage_type_id)
    end
    @url            = {"url" => ""}
    @file_path      = file_path
    @public_url = public_url
  end

  def call
    return_url
    url
  end

  def read_file
    begin
      fetch_object.get.body.read
    rescue => exception
      nil
    end
  end

  def delete_file
    configure_aws
    s3 = Aws::S3::Resource.new
    s3.bucket(cloud_storage_type.bucket).object(@file_path).delete if @file_path
  end

  def read_diff_cst_file(cst)
    begin
      fetch_object_v2(cst).get.body.read
    rescue => exception
      nil
    end
  end

  private

  attr_reader :file_path, :cloud_storage_type, :url, :public_url

  def configure_aws
    path = Rails.root.join('./config/creds').to_path
    filename = "#{cloud_storage_type.bucket}_creds.json"
    full_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(full_path))
    Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])
    Aws.config.update({region: cloud_storage_type.region})
  end

  def return_presigned_url
    s3   = Aws::S3::Resource.new
    item = s3.bucket(cloud_storage_type.bucket).object(file_path)
    authenticated_url  = item.presigned_url(:get, expires_in: cloud_storage_type.link_expiration_duration.to_i)
    url["url"] = authenticated_url
  end

  def return_public_url
    s3   = Aws::S3::Resource.new
    item = s3.bucket(cloud_storage_type.bucket).object(file_path)
    url['url'] = item.public_url
  end

  def fetch_object
    configure_aws
    s3 = Aws::S3::Resource.new
    s3.bucket(cloud_storage_type.bucket).object(file_path)
  end

  def fetch_object_v2(cst)
    configure_aws
    s3 = Aws::S3::Resource.new
    s3.bucket(cst.bucket).object(file_path)
  end

  def return_url
    if !cloud_storage_type.blank?
      configure_aws
      if public_url
        return_public_url
      else
        return_presigned_url
      end
    else
      url["url"] = file_path
    end
  end

end
