class FileAsset < ApplicationRecord
  belongs_to :cloud_storage_type
  belongs_to :blob, polymorphic: true

  def save_medal_image(image_file)
    target_path = Rails.root.join('public', 'medal_images')
    self.name = self.blob_id.to_s + '_' + self.blob_type + File.extname(image_file.original_filename)
    self.cloud_storage_type = CloudStorageType.find_by_bucket('videokaddy')
    #puts "----- #{target_path.to_path} ------"
    FileUtils.mkdir_p(target_path.to_path) unless File.directory? target_path.to_path
    UploadMedalImage.new({image_file: image_file, target_path: target_path,
      cloud_storage_type: self.cloud_storage_type, file_asset: self}).save_and_upload
    save!
  end

  def get_aws_url
    file_path = Rails.root.join('config', 'creds').to_path
    filename = "#{cloud_storage_type.bucket}_creds.json"
    full_path = "#{file_path}/#{filename}"
    creds = JSON.load(File.read(full_path))
    Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])
    Aws.config.update({region: cloud_storage_type.region})
    s3   = Aws::S3::Resource.new
    s3.bucket(cloud_storage_type.bucket).object(self.path).presigned_url(:get, expires_in: cloud_storage_type.link_expiration_duration.to_i)
  end
end
