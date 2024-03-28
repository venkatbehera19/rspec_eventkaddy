require 'net/http'
require 'open-uri'
require 'active_record'
require 'aws-sdk-s3'
require 'json'
require 'digest/md5'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'


############## ADD URLS from Amazon s3 #####################################

def get_url_array(s3_region,bucket,s3_path)
  path = Rails.root.join('./config/creds').to_path
  filename = "#{bucket}_creds.json"
  full_path = "#{path}/#{filename}"
  creds = JSON.load(File.read(full_path))
  Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])

  s3 = Aws::S3::Resource.new(region:s3_region)
  url_array = []
  s3.bucket(bucket).objects.each do |obj|
    url = obj.key
    url_array << url
  end
  url_array
end

def return_filename(filename,ext)
  filename + "." + ext
end

def check_for_file(session,base_url, url_array)
  filename = session.video_file_location
  unless filename.blank? 
    url_array.each do |item|
      if (item.include? filename) && (!item.include? "_720") && (!item.include? "_360")
        url =  base_url + item
        session.update!(embedded_video_url:url)
      end
    end
  end
end

# establish_connection DRUPAL_DB
ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

session_id = ARGV[0]
s = Session.find(session_id)
event_id = s.event_id

cs_type = CloudStorageType.find(Event.find(event_id).cloud_storage_type_id)
s3_region = cs_type.region
bucket = cs_type.bucket
base_url = "https://s3-#{s3_region}.amazonaws.com/#{bucket}/"
s3_path  = "event_data/#{event_id}/session_videos/"

puts bucket
puts s3_region
url_array = get_url_array(s3_region,bucket,s3_path)

check_for_file(s,base_url,url_array)
