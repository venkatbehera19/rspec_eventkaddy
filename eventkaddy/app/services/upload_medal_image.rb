require 'aws-sdk-s3'

class UploadMedalImage
  include Magick

  def initialize(args)
    @image_file = args[:image_file]
    @target_path = args[:target_path]
    @cloud_storage_type = args[:cloud_storage_type]
    @file_asset = args[:file_asset]
  end

  attr_reader :image_file, :target_path, :cloud_storage_type, :file_asset

  def full_path
    "#{target_path}/#{file_asset.name}"
  end

  def configure_and_set_client
    @bucket = cloud_storage_type.bucket
    @region = cloud_storage_type.region
    path = Rails.root.join('./config/creds').to_path
    filename = "#{@bucket}_creds.json"
    creds_path = "#{path}/#{filename}"
    creds = JSON.load(File.read(creds_path))
    @client = Aws::S3::Client.new(region: @region, access_key_id: creds['AccessKeyId'],secret_access_key: creds['SecretAccessKey'])
  end

  def write_image
    File.open(full_path, 'wb', 0777) {|f| f.write(image_file.read) }    
    puts '---- File writen to the server --------'
  end

  def resize_and_write
    img = Magick::Image::read(full_path).first
    img.change_geometry("400x400") {|cols, rows, image|  image.resize!(cols, rows)}
    img.write(full_path)
    file_asset.size = img.filesize
    file_asset.path = full_path.sub(Rails.root.join('public').to_path, '')
    puts '------ sized and saved ------'
  end

  def upload_file_to_s3
    configure_and_set_client
    s3 = Aws::S3::Resource.new(client: @client)
    obj = s3.bucket(@bucket).object(full_path.sub(Rails.root.join('public').to_path, ''))
    if obj.upload_file(full_path, acl: 'public-read')
      puts '----- saved to s3 -------'
      puts obj.public_url
    else
      puts 'Error uploading to s3'
    end
    FileUtils.rm full_path, force: true
  end

  def delete_medal
    configure_and_set_client
    s3 = Aws::S3::Resource.new(client: @client)
    obj = s3.bucket(@bucket).object(file_asset.path)
    obj.delete
    puts '----- File has been deleted from s3 ------------'
  end

  def save_and_upload
    write_image
    resize_and_write
    upload_file_to_s3
  end
end