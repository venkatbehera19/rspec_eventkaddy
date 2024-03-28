require 'roo'
require 'uri'
require 'net/https'
require 'open-uri'


#for active record usage
require 'active_record'
require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'

#load the rails 3 environment
require_relative '../../config/environment.rb'
require_relative '../../config/initializers/global_constants.rb'

def return_sanitize_for_db(string_to_sanitize)
  string = string_to_sanitize
  string.gsub('<br>', '')
  string.gsub('Ⓡ', '')
end

def apiFetchAuthSwooho
  url = URI("https://www.swoogo.com/api/v1/oauth2/token.json")

  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true

  request = Net::HTTP::Post.new(url)
  request["Content-Type"] = "application/x-www-form-urlencoded"
  auth_cred = Base64.urlsafe_encode64("#{MATRIX_SWOOHO_CLIENT_ID}:#{MATRIX_SWOOHO_CLIENT_SECRET}")
  request["Authorization"] = "Basic #{auth_cred}"
  request.body = "grant_type=client_credentials"
  response = https.request(request)
  raise TypeError.new JSON.parse(response.body)["message"] if response.code != "200"
  response_json = JSON.parse(response.body)
end


def fetchSessions(token, token_expires_at,page)
  url = URI("https://www.swoogo.com/api/v1/sessions.json?event_id=58523&fields=name,description,date,start_time,end_time,notes,type_id,location,c_49569,c_49523,c_49522,webinar_url,id,category&expand=&search=&page=#{page}&per-page=200&sort")

  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  request = Net::HTTP::Get.new(url)
  if DateTime.parse(token_expires_at) > DateTime.now.utc
    auth_token = token
  else
    get_token = apiFetchAuthSwooho
    auth_token = get_token["access_token"]
  end 
  request["Authorization"] = "Bearer #{auth_token}"
  form_data = []
  request.set_form form_data, 'multipart/form-data'
  response = https.request(request)
  raise TypeError.new JSON.parse(response)["message"] if response.code != "200"
  JSON.parse(response.body)
end

def fetchAllSessions(token, token_expires_at, page, total_page, sessions_arr)
  if page <= total_page
    getSessions = fetchSessions(token, token_expires_at, page)
    page += 1
    total_page = getSessions["_meta"]["pageCount"]
    sessions_arr << getSessions["items"]
    fetchAllSessions(token, token_expires_at, page, total_page, sessions_arr, )
  end
  sessions_arr.flatten
end

def return_sessions_attribute_hash(session)
  session_code        = session["id"]
  session_title       = return_sanitize_for_db(session["name"])
  session_description = session["description"]

  #temporary fix until published field is working in app
  # if published == true then (used in 2017)
  @api_session_ids << session["id"].to_s

  if session["start_time"].present? 
    stime            = Time.parse(session["start_time"])
    session_start_at = stime.strftime('%R:%S')
  else
    session_start_at = "07:21:00"
  end

  if session["end_time"].present?
    etime          = Time.parse(session["end_time"])
    session_end_at = etime.strftime('%R:%S')
  else
    session_end_at = "07:21:00"
  end

  if session["date"].present? then
    session_date = session["date"]
  else
    session_date = "2022-08-08"
  end


  session_attrs = {event_id: @event_id, unpublished: true, session_code: session_code, title:session_title, description:session_description, date:session_date, start_at: session_start_at, end_at: session_end_at}
end

def create_or_update_session_and_return_ar_object(session_attrs)
  session_code = session_attrs[:session_code]
  sessions_r = Session.where(session_code:session_code, event_id:@event_id)
  if (sessions_r.length==0)
    ar_session = Session.create!(session_attrs)
  elsif (sessions_r.length==1)
    ar_session = sessions_r[0]
    ar_session.update!(session_attrs)
  end
  ar_session
end

def get_full_name(name)
  case name
  when "LPC"
    full_name = "Life plan communities"
  when "SNF"
    full_name = "Skilled nursing"
  when "SL"
    full_name = "Senior living"
  else
    full_name = name           
  end
  return full_name
end


def collect_session_tags_from_data(session, ar_session)
  categories = session["c_49569"]["value"]
  tags = []
  categories.split(",").each do |category|
    fullname = get_full_name(category.strip)
    tags << [fullname]
  end
  tags
end

def return_tags_safeguard(tags)

  def end_of_array?(index, array)
    (index+1)===array.length
  end

  tags_safeguard = ''

  if tags.length > 0
    tags.each_with_index do |tag_group, i|
      tag_group.each_with_index {|t, i| tags_safeguard += end_of_array?(i, tag_group) ? t : "#{t}||" }
      tags_safeguard += '^^' unless end_of_array?(i, tags)
    end
  end
  tags_safeguard
end


ActiveRecord::Base.establish_connection(:adapter => "mysql2",:host => @db_host,:username => @db_user,:password => @db_pass,:database => @db_name)


@event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'SWOOGO API', row:0, status:'In Progress')
end

if JOB_ID && @event_id

  job.start {
    @api_session_ids = []

    job.status  = 'Fetching data from API'
    job.write_to_file
    auth     = apiFetchAuthSwooho
    token    = auth["access_token"]
    token_expires_at = auth["expires_at"] #in utc
    fetch_sessions = fetchAllSessions(token, token_expires_at, 1, 1, [])
    job.update!(total_rows: fetch_sessions.length, status:'Processing Rows')
    job.write_to_file

    fetch_sessions.each do |session|
      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0
      session_attrs = return_sessions_attribute_hash(session)
      ar_session = create_or_update_session_and_return_ar_object(session_attrs)
      unless session["c_49569"].nil?
        tags = collect_session_tags_from_data(session, ar_session)
        ar_session.update_tags tags, 'session'
        ar_session.update(tags_safeguard: return_tags_safeguard(tags))
      else
        puts "empty: #{session["c_49569"]}"
      end
    end

    job.status  = 'Cleanup'
    job.write_to_file
    #Remove sessions that did not appear in their refresh
    session_codes = Session.where(event_id: @event_id).pluck(:session_code)
    unless @api_session_ids.empty?
      session_codes_to_destroy = session_codes - @api_session_ids
      puts "----- destroying session_codes for event #{@event_id}: #{session_codes_to_destroy} --------"
      Session.where(event_id:@event_id, session_code: session_codes_to_destroy).destroy_all
    end
  }
end


