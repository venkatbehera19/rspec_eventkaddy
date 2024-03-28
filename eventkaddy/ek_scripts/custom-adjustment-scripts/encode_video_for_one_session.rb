# Converting videos with Elemental MediaConvert
# For new batch, update encoding presets if needed

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

def create_job(mediaconvertclient,file_name,bucket,s3_path)
  begin
    mediaconvertclient.create_job({
    queue: "arn:aws:mediaconvert:us-west-1:520316411820:queues/Videokaddy",
    role: "arn:aws:iam::520316411820:role/Encoder",
    settings: {
      output_groups: [
        {
          name: "File Group",
          outputs: [
            {
              preset: "1280x720 HQ",
              name_modifier: "_720"
            }
          ],
          output_group_settings: {
            type: "FILE_GROUP_SETTINGS",
            file_group_settings: {
              destination: "s3://#{bucket}/#{s3_path}"
            }
          }
        },
        {
          name: "File Group",
          outputs: [
            {
              preset: "640x360 HQ",
              name_modifier: "_360"
            }
          ],
          output_group_settings: {
            type: "FILE_GROUP_SETTINGS",
            file_group_settings: {
              destination: "s3://#{bucket}/#{s3_path}"
            }
          }
        }
      ],
      ad_avail_offset: 0,
      inputs: [
        {
          audio_selectors: {
            "Audio Selector 1" => {
              offset: 0,
              default_selection: "DEFAULT",
              selector_type: "PID",
              program_selection: 1
            }
          },
          file_input: "s3://#{bucket}/#{s3_path}#{file_name}",
          video_selector: {
            color_space: "FOLLOW"
            # ,
            # rotate: "DEGREE_0"
          },
          filter_enable: "AUTO",
          psi_control: "IGNORE_PSI",
          filter_strength: 0,
          deblock_filter: "DISABLED",
          denoise_filter: "DISABLED",
          timecode_source: "ZEROBASED"
        }
      ]
    }
  })
  rescue Aws::MediaConvert::Errors::ServiceError
  # rescues all service API errors
  end
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
  else
    puts "lets run script #{file_name}--------------!"
    create_job(mediaconvertclient,file_name,bucket,path)
  end
end


