###########################################
#Ruby script to import spekaer data from
#Planstone API to EventKaddy CMS
###########################################

#BCBS SPEAKERS - Data and Photos


require 'roo'
require 'net/http'
require 'open-uri'

#for active record usage
require 'active_record'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'

#load the rails 3 environment
require_relative '../../config/environment.rb'
require_relative '../../config/initializers/global_constants.rb'

def authenticate_api(uri)
   Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') do |http|

    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth BCBS2022_AUTH, ''

    response = http.request request # Net::HTTPResponse object

    url = response.body
    parsed_url = JSON.parse(url)
    return parsed_url
  end
end

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

def update_speaker_photo(ar_speaker)

  event_id   = @event_id
  event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id

    if ar_speaker.photo_event_file_id != nil && ar_speaker.photo_event_file_id != ''
      #update the speaker photo
      event_file = EventFile.find(ar_speaker.photo_event_file_id)
      target_path = Rails.root.join('public', 'event_data', event_id.to_s, 'speaker_photos').to_path
      #old_photo_name = event_file.name
      # FileUtils.rm("#{target_path}/#{old_photo_name}",:force => true)
      process_image(ar_speaker)
    else
      #create a new speaker photo
      process_image(ar_speaker)
    end
end

def process_image(ar_speaker)

  photo_event_file_id = ar_speaker.photo_event_file_id
  event_id            = @event_id
  event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id
  event_file          = photo_event_file_id ? EventFile.find(photo_event_file_id)
                                     : EventFile.create(event_id:event_id,event_file_type_id:event_file_type_id)
  filename        = "#{ar_speaker.first_name}_#{ar_speaker.last_name}_photo.jpg"
  
  target_path     = Rails.root.join('public', 'event_data', event_id.to_s, 'speaker_photos').to_path
  FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  event_file_path = "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{filename}"
  
  temp_path       = Rails.root.join('temp_file_processing', 'event_data', event_id.to_s, 'speaker_photos').to_path
  FileUtils.mkdir_p(temp_path) unless File.directory?(temp_path)

  temp_filepath     = "#{temp_path}/#{filename}"
  target_filepath   = "#{target_path}/#{filename}"

  image           = ar_speaker.custom_filter_2

  File.open(temp_filepath, 'wb', 0777) {|f|
    f.write(open(image).read)}
  img = Magick::Image::read(temp_filepath).first
  img.change_geometry("300x400 #{true ? '' : '!'}") {|cols, rows, image|
  image.resize!(cols,rows)}
  img.write(temp_filepath)

  #if image saved successfully
  if File.file?(temp_filepath)
    #if there is an existing image
    if File.file?(target_filepath)
      FileUtils.rm target_filepath
    end
    FileUtils.mv temp_filepath, target_path
    event = Event.find event_id
    raise "Please set cloud storage type for the event" if event.cloud_storage_type_id.blank?
    cloud_storage_type = CloudStorageType.find event.cloud_storage_type_id
    UploadEventFile.new({
      event_file: event_file,
      file: File.open(target_path),
      target_path: target_path,
      new_filename: filename,
      cloud_storage_type: cloud_storage_type,
      content_type: MIME::Types.type_for(target_filepath).first.content_type,
      public_ack: true
    }).call
  end

  full_event_file_path = "https://admin.eventkaddy.net" + event_file_path
  event_file.update!(name:filename,path:event_file_path)
  ar_speaker.update!(photo_event_file_id:event_file.id, photo_filename:full_event_file_path)

end

def url_exist?(url_string)
  url = URI.parse(url_string)
  req = Net::HTTP.new(url.host, url.port)
  req.use_ssl = (url.scheme == 'https')
  path = url.path if url.path.present?
  res = req.request_head(path || '/')
  res.code != "404" # false if returns 404 - not found
rescue Errno::ENOENT
  false # false if can't find the server
end

@event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'Planstone API', row:0, status:'In Progress')
end

job.start {

  api_speaker_ids = []

  planstone_url = 'https://apps.planion.com/feed/v1/speakers?where=%7B%22account%22%3A%22BCBSNS%22%2C%22conference%22%3A%22NM22%22%7D'

  uri = URI(planstone_url)

  parsed_url = authenticate_api(uri)
  pages = parsed_url["_meta"]

  max_results = pages["max_results"]
  total_records = pages["total"]

  total_pages = (total_records/max_results.to_f).ceil

  puts total_pages, total_records, max_results

  page = 1
  count = 0

  while page <= total_pages

    job.status  = 'Fetching data from API'
    job.write_to_file

    page_url = "&page=#{page}"

    sessions_url = planstone_url + page_url

    uri = URI(sessions_url)
    parsed_url = authenticate_api(uri)
    speakers = parsed_url["_items"]

    session_ids = Session.where(event_id:@event_id).pluck(:id)

    job.update!(total_rows:total_records, status:'Processing Rows')
    job.write_to_file

    #process all retrieved sessions
    speakers.each do |speaker|

      event_id = @event_id
      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

      api_speaker_ids << speaker["pid"]
      #column mappings
      speaker_code          = speaker["pid"]
      speaker_first_name    = return_titleized_name(speaker["fname"])
      speaker_last_name     = return_titleized_name(speaker["lname"].gsub(/,/,''))
      speaker_title         = speaker["title"]
      speaker_company       = speaker["company"]
      speaker_biography     = speaker["bio"]
      photo_filename_link   = speaker["piclink"]

      #Add Speakers
      speaker_attrs = {event_id:event_id,first_name:speaker_first_name,last_name:speaker_last_name,company:speaker_company, speaker_code:speaker_code, biography:speaker_biography, custom_filter_2:photo_filename_link, title:speaker_title}

      speaker_results = Speaker.where(speaker_code:speaker_code,event_id:event_id)

      if (speaker_results.length==0) then
        puts "creating speaker"
        speaker_r = Speaker.new(speaker_attrs)
        speaker_r.save
      elsif (speaker_results.length==1)
        puts "updating speaker"
        speaker_r = speaker_results[0]
        speaker_r.update!(speaker_attrs)
        count +=1
        # puts "count = #{count}
      end

    end #speakers

    job.status  = 'Cleanup'
    job.write_to_file

    #important to avoid infinite loop
    page +=1
  end #pages
  speaker_count = 0
  job.row = 0

  speakers = Speaker.where(event_id:@event_id)

  speakers.each do |ar_speaker|

    speaker_count +=1
    puts speaker_count

    job.update!(total_rows:speakers.length, status:'Processing Photos')
    job.write_to_file

    job.status = 'Processing Photos'
    job.row    = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0

    puts "name: #{ar_speaker.first_name} #{ar_speaker.last_name}"

    if ar_speaker.custom_filter_2 != '' && ar_speaker.custom_filter_2 != nil then
      if url_exist?(ar_speaker.custom_filter_2)
        update_speaker_photo(ar_speaker)
      else
        puts "ALERT: 401 ERROR"
      end
    end
  end #speakers

  # Remove speakers that did not appear in their refresh. Needs to be outside of pages loop
  puts "API SPEAKER IDS: #{api_speaker_ids}"

  speaker_codes = Speaker.where(event_id:@event_id).pluck(:speaker_code)
  speaker_codes_to_destroy = speaker_codes - api_speaker_ids
  puts api_speaker_ids.count
  puts "----- destorying speaker_codes for event #{@event_id}: #{speaker_codes_to_destroy} --------"

  Speaker.where(event_id:@event_id, speaker_code:speaker_codes_to_destroy).destroy_all

  #update the unpublished field if there is no data from sessions integration
  # ar_speakers = Speaker.where(event_id:@event_id)

  # ar_speakers.each do |ar_speaker|

  #   if ar_speaker.unpublished != false
  #     unpublished = true
  #   else
  #     unpublished = false
  #   end
  #   ar_speaker.update!(unpublished:unpublished)
  #   puts "#{ar_speaker.speaker_code} and #{ar_speaker.unpublished} and #{ar_speaker.id} and #{ar_speaker.first_name}"
  # end

} #job.start
