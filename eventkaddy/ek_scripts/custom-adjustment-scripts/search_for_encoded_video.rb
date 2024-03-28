# Searching for encoded videos

require 'net/http'
require 'open-uri'
require 'active_record'
require 'aws-sdk-s3'
require 'json'
require 'digest/md5'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

def setup_credentials(bucket, s3_region)
  path = Rails.root.join('./config/creds').to_path
  filename = "#{bucket}_creds.json"
  full_path = "#{path}/#{filename}"
  creds = JSON.load(File.read(full_path))
  Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])
  s3 = Aws::S3::Resource.new(region:s3_region)
  mediaconvertclient = Aws::MediaConvert::Client.new(
    :access_key_id => creds['AccessKeyId'],
    :secret_access_key => creds['SecretAccessKey'],
    # :profile => "default",
    #this doesn't change - based on mediaconvert not s3
    :region=>'us-west-1', 
    :endpoint => "https://4nyhswgta.mediaconvert.us-west-1.amazonaws.com"
  )
  url_array = []
  s3.bucket(bucket).objects.each do |obj|
    url = obj.key
    url_array << url
  end
  return url_array, mediaconvertclient
end

def update_database_with_encoded_video(s,file_location)
  encoded_videos = [{},{},{}]
  encoded_videos[0]["label"] = "1080p"
  encoded_videos[0]["src"] = s.video_file_location
  encoded_videos[0]["type"] = "video/mp4"
  encoded_videos[1]["label"] = "360p"
  encoded_videos[1]["src"] = URI.escape("#{file_location}_360.mp4")
  encoded_videos[1]["type"] = "video/mp4"
  encoded_videos[2]["label"] = "720p"
  encoded_videos[2]["src"] = URI.escape("#{file_location}_720.mp4")
  encoded_videos[2]["type"] = "video/mp4"
  s.update!(encoded_videos:encoded_videos.to_json)
end

ActiveRecord::Base.establish_connection(:adapter => "mysql2",:host => @db_host,:username => @db_user,:password => @db_pass,:database => @db_name)


session_id = ARGV[0]
s = Session.find(session_id)
event_id = s.event_id

cs_type = CloudStorageType.find(Event.find(event_id).cloud_storage_type_id)
s3_region = cs_type.region
bucket = cs_type.bucket
base_url = "https://s3-#{s3_region}.amazonaws.com/#{bucket}/"
url_array, mediaconvertclient = setup_credentials(bucket,s3_region)

unless s.video_file_location.blank?
  file_name = s.video_file_location.split('/')[-1]
  path = s.video_file_location.gsub(file_name, "")
  name_720 = s.video_file_location[0..-5] + "_720.mp4"
  name_360 = s.video_file_location[0..-5] + "_360.mp4"
  if (url_array.include? name_720) || (url_array.include? name_360)
    puts "already exists #{file_name}"
    update_database_with_encoded_video(s,s.video_file_location[0..-5])
  else
    puts "File doesn't exist"
  end
end


