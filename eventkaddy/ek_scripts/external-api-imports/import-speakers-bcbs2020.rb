###########################################
#Ruby script to import speaker data from
#Planstone API to EventKaddy CMS
###########################################

#BCBS SPEAKERS - Data Only


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
    request.basic_auth BCBS2020_AUTH, ''

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

@event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'Planstone API', row:0, status:'In Progress')
end

job.start {

  planstone_url = 'https://static.planion.com/feed/v1/speakers?where=%7B%22account%22%3A%22BCBSNS%22%2C%22conference%22%3A%22NM20%22%7D'

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

    job.update!(total_rows:total_records, status:'Processing Rows')
    job.write_to_file

    #process all retrieved sessions
    speakers.each do |speaker|

      event_id = @event_id
      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

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
      end

    end #speakers

    #important to avoid infinite loop
    page +=1
  end #pages

} #job.start
