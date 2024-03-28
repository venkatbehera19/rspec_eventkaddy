require 'net/http'
require 'open-uri'
require 'active_record'
require 'aws-sdk-s3'
require 'json'
require 'digest/md5'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

def create_or_update_thumbnails(ar_session)
  @event_file_type_id  = EventFileType.where(name:'session_thumbnail').first.id

  if ar_session.thumbnail_event_file_id != nil && ar_session.thumbnail_event_file_id != ''
    event_file = EventFile.find(ar_session.thumbnail_event_file_id)
    puts "updating photo"
    target_path = Rails.root.join('public', 'event_data', ar_session.event_id.to_s, 'session_thumbnails').to_path
    old_photo_name = event_file.name
    FileUtils.rm("#{target_path}/#{old_photo_name}",:force => true)
    process_image(ar_session)
  else
    puts "creating new photo"
    process_image(ar_session)
  end
end

def process_image(ar_session)
  thumbnail_event_file_id = ar_session.thumbnail_event_file_id
  event_file          = thumbnail_event_file_id ? EventFile.find(thumbnail_event_file_id)
                                     : EventFile.create(event_id:ar_session.event_id,event_file_type_id:@event_file_type_id)
  filename        = ar_session.session_code + ".jpg"
  target_path     = Rails.root.join('public', 'event_data', ar_session.event_id.to_s, 'session_thumbnails').to_path
  FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  event_file_path = "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{filename}"
  full_path       = "#{target_path}/#{filename}"
  url_hash = ar_session.return_authenticated_url(ar_session.event_id,ar_session.video_file_location)
  url = url_hash["url"]
  img = system("ffmpeg -ss 00:00:00 -i '#{url}' -vf scale=320:-1  -vframes:v 1 -q:v 2 '#{full_path}'")

  if img == true
    #consider using full_event_file_path instead of event_file_path when the server name is correct
      #@event = Event.find(ar_session.event_id)
      #full_event_file_path =  @event.event_server + event_file_path
    size = File.size(full_path)
    event_file.update!(name:filename,path:event_file_path,size:size,mime_type:'jpg',)
    ar_session.update!(thumbnail_event_file_id:event_file.id, video_thumbnail:event_file_path)
  else
    @image_errors << url
  end
end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

session_id = ARGV[0]

@image_errors = []

s = Session.find(session_id)
event_id = s.event_id

if !s.video_file_location.blank?
  create_or_update_thumbnails(s)
end

puts @image_errors


