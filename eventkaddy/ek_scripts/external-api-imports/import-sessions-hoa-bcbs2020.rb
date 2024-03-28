require 'net/http'
require 'open-uri'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'

def return_session_attributes_hash(session, event_id)
  if session["product_description"]
    description = session["product_description"]
    .gsub("<span style=\"font-size: 14px; font-family: Arial, Helvetica, sans-serif;\">", "")
    .gsub("</span>", "")
    .gsub("&amp;","&")
    .gsub("<br />", "")
    .gsub("&nbsp;", " ")
  else
    description = ""
  end

  {event_id:          event_id,
   session_code:      session["id"],
   title:             session["product_name"],
   custom_filter_1:   session["data_tag_code"],
   custom_filter_1:   "",
   description:       description,
   location_mapping_id: return_location_mapping_id(session["session_location_name"]),
   date:              session["start_time"],
   start_at:          session["start_time"],
   end_at:            session["end_time"]
 }
end

def return_session_rows(session_attrs)
  Session.where(session_code:session_attrs[:session_code],event_id:session_attrs[:event_id])
end

def return_location_mapping_id(room)
  type_id = LocationMappingType.where(type_name:"Room").first.id
  return LocationMapping.where(event_id:@event_id, name:room, mapping_type:type_id).first_or_create.id
end

# def add_prefavourites(session_id)
#   PREFAVOURITES.each {|p|
#     SessionsSession.where(session_id:session_id, flag:'cms_external_api', session_id:p[:session_id], session_code:p[:session_code]).first_or_create }
# end

def create_or_update_session_with_msg(session_attrs)

  rows           = return_session_rows(session_attrs)
  create_message = "--- creating session: #{session_attrs[:session_code]} #{session_attrs[:first_name]} ---\n".green
  update_message = "---- updating session: #{session_attrs[:session_code]} #{session_attrs[:first_name]} ----\n".yellow
  error_message  = "ERROR: Multiple rows for session #{session_attrs[:session_code]} #{session_attrs[:first_name]}".red

  if rows.length == 0
    msg = create_message
    Session.create(session_attrs)
  elsif rows.length == 1
    msg = update_message
    rows[0].update!(session_attrs)
  else
    msg = error_message
  end

  puts msg
end

def create_or_update_session(session_attrs)
  session = return_session_rows(session_attrs)
                       .first_or_initialize
  session.update!(session_attrs)
  session
end

def remove_session(session_attrs)
  rows           = return_session_rows(session_attrs)
  delete_message = "--- deleted cancelled session: #{session_attrs[:session_code]} #{session_attrs[:first_name]} ---\n".green
  error_message  = "ERROR: Multiple rows for session #{session_attrs[:session_code]} #{session_attrs[:first_name]}, did not delete cancelled session".red

  if rows.length == 1
    msg = delete_message
    rows[0].destroy
  elsif rows.length > 1
    msg = error_message
  end

  puts msg
end

# def return_plan_tagset_array(session_attrs)
#   ['BCBS Plan/Company', session_attrs[:custom_filter_1]]
# end

def return_data_tag_code_tagset_array(session_attrs)
  [session_attrs[:custom_filter_1]]
end

# def return_title_tagset_array(session_attrs)
#   ['Title', session_attrs[:title]]
# end

def return_session_tag_array(session_attrs)
  tag_array = []
  tag_array << return_data_tag_code_tagset_array(session_attrs) unless session_attrs[:custom_filter_1].blank?
  # tag_array << return_business_dicipline_tagset_array(session_attrs) unless session_attrs[:business_unit].blank?
  #not including title tags as tagset too random
  # tag_array << return_title_tagset_array(session_attrs)              unless session_attrs[:title].blank?
  puts tag_array
  tag_array
end

# def return_tags_safeguard(session_tag_array)

#   def end_of_array?(index, array)
#     (index+1)===array.length
#   end

#   tags_safeguard = ''

#   if session_tag_array.length > 0
#     session_tag_array.each_with_index do |tag_group, i|
#       tag_group.each_with_index {|t, i| tags_safeguard += end_of_array?(i, tag_group) ? t : "#{t}||" }
#       tags_safeguard += '^^' unless end_of_array?(i, session_tag_array)
#     end
#   end
#   tags_safeguard
# end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

HOST          = 'https://bcbsproxyb.eventkaddy.net'
# HOST            = 'http://localhost:3001'
sessions_url = HOST + '/sessions_hoa_2020?proxy_key=' + MERCURY_CREDS

event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'CVENT API', row:0, status:'In Progress')
end

if JOB_ID && event_id

  job.start {

    job.status  = 'Fetching data from API'
    job.write_to_file
    sessions     = JSON.parse(apiFetch(sessions_url))
    puts sessions

    job.update!(total_rows:sessions.length, status:'Processing Rows')
    job.write_to_file

    sessions.each do |session|

      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0

      session_attrs                  = return_session_attributes_hash(session, event_id)

      create_or_update_session_with_msg(session_attrs)
      ar_session = create_or_update_session(session_attrs)
    end

    job.status  = 'Cleanup'
    job.write_to_file

  }
end
