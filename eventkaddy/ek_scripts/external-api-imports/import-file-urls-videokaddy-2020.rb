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

def get_url_array(job)
  path = Rails.root.join('./config/creds').to_path
  filename = 'videokaddy_creds.json'
  full_path = "#{path}/#{filename}"
  creds = JSON.load(File.read(full_path))
  Aws.config[:credentials] = Aws::Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'])

  s3 = Aws::S3::Resource.new(region:'us-west-1')
  puts "s3:#{s3}"
  @url_array = []
  job.update!(total_rows:"100", status:'Processing Rows')
  job.write_to_file
  s3.bucket("videokaddy").objects.each do |obj|
    url = obj.key
    @url_array << url
    job.row    = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0
  end
  print @url_array
end

def return_filename(filename,ext)
  filename + "." + ext
end

def check_for_file(session)

  filename = session.session_code
  salt = "9$0384i$2dpfer$7f0pm5u901"
  hashed_file = Digest::MD5.hexdigest(Digest::MD5.hexdigest(salt + filename))
  md5_filename = hashed_file

  unless @url_array.empty?
    print @url_array
    print @url_array.class
    print session.event_directory
    @url_array.each do |item|
      if item.include? session.event_directory
        if item.include?(return_filename(filename,"mp4")) || item.include?(return_filename(filename,"mov")) || item.include?(return_filename(md5_filename,"mp4")) || item.include?(return_filename(md5_filename,"mov"))
            session.update!(video_file_location:item)
            session.update!(embedded_video_url:item)
        elsif item.include?(return_filename(filename,"mp3")) || item.include?(return_filename(md5_filename,"mp3"))
            session.update!(audio_file_location:item)
        elsif item.include?(return_filename(filename,"srt")) || item.include?(return_filename(md5_filename,"srt")) || item.include?(return_filename(md5_filename,"vtt")) || item.include?(return_filename(filename,"vtt"))
            session.update!(subtitle_file_location:item)
        end
      end
    end
  end
end

# establish_connection DRUPAL_DB
ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'', row:0, status:'In Progress')
end

if JOB_ID && event_id

  job.start {

    job.status  = 'Fetching data from videokaddy'
    job.write_to_file

    get_url_array(job)

    sessions = Session.where(event_id: event_id)
    job.update!(total_rows:sessions.length, status:'Processing Rows')
    job.write_to_file
    job.row    = 0
    sessions.each do |session|
      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0
      check_for_file(session)
    end
  }
end