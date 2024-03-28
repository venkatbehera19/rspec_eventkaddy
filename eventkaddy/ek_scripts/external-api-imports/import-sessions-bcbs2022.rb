###########################################
#Ruby script to import session data from
#Planstone EventKaddy CMS
###########################################
#look into updating published/unpublished field - workaround was used last year (2017), see sessions attributes hash method
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

def get_total_records(uri)
  parsed_url = authenticate_api(uri)
  pages = parsed_url["_meta"]
  max_results = pages["max_results"]
  total_records = pages["total"]
  total_pages = (total_records/max_results.to_f).ceil
  puts total_pages, total_records, max_results
  return total_records, total_pages
end

def return_location_mapping_id(room)
  type_id = LocationMappingType.where(type_name:"Room").first.id
  return LocationMapping.where(event_id:@event_id, name:room, mapping_type:type_id).first_or_create.id
end

def return_sessions_attribute_hash(session)
  session_code        = session["sesid"]
  session_title       = return_sanitize_for_db(session["sessionName"])
  session_description = session["description"]
  published           = session["published"]
  learning_objectives_array = []
  learning_objective = nil

  if published == true then
    unpublished = false
  else
    unpublished = true
  end

  #temporary fix until published field is working in app
  # if published == true then (used in 2017)
  @api_session_ids << session["sesid"]

  #value "credits and type"
  accreditation_field = session["custom2name"]

  #if (accreditation_field.length > 0 && accreditation_field != "credits and type") then
if (accreditation_field.present? && accreditation_field != "credits and type") then
    acceditation_value = promotion;
  else
    accreditation_value = nil
  end

  #create json mapping for custom fields
  custom_fields = [{}]
  custom_fields[0]["title"] = "Credits and type"
  custom_fields[0]["value"] = accreditation_value
  custom_fields[0]["value"] = session["custom2"]

  if session["startTime"].present? then
    stime            = Time.parse(session["startTime"])
    session_start_at = stime.strftime('%R:%S')
  else
    session_start_at = "07:21:00"
  end

  if session["endTime"].present? then
    etime          = Time.parse(session["endTime"])
    session_end_at = etime.strftime('%R:%S')
  else
    session_end_at = "07:21:00"
  end

  if session["startDate"].present? then
    session_date = session["startDate"]
  else
    session_date = "2018-05-01"
  end

  if (session["sched_roomname"]!=nil) then
    @room = session["sched_roomname"]
  else
    @room = ''
  end

  puts "room: #{@room}"

  # if (session["custom3name"] == "Learning Objectives")
  #   if (session["custom3"] != nil) then
  #     learning_objective = session["custom3"]
  #   end
  # end
  (1..10).each do |ind|
    learning_objectives_array.push(session["learning_objective#{ind}"]) unless session["learning_objective#{ind}"].blank?
  end

  if learning_objectives_array.length > 0
    learning_objective = "<ul>#{ learning_objectives_array.inject("") {|acc, ele| acc += "<li>#{ele}</li>"} }</ul>"
  end


  location_mapping_id = return_location_mapping_id(@room)
  puts "location_mapping: #{location_mapping_id}"

  session_attrs = {event_id:@event_id, unpublished:unpublished, session_code:session_code,title:session_title,description:session_description, date:session_date,start_at:session_start_at, end_at:session_end_at, custom_fields:custom_fields.to_json, learning_objective:learning_objective, location_mapping_id:location_mapping_id}
end

def create_or_update_session_and_return_ar_object(session_attrs)
  session_code = session_attrs[:session_code]
  sessions_r = Session.where(session_code:session_code,event_id:@event_id)
  if (sessions_r.length==0) then
    ar_session = Session.create!(session_attrs)
  elsif (sessions_r.length==1) then
    ar_session = sessions_r[0]
    ar_session.update!(session_attrs)
  end
  ar_session
end

#method converts acronyms to full name of audience field
def return_full_audience_name(track_desc_org)
  track_desc = track_desc_org.to_s.gsub("<br>", "")
  case track_desc
  when "(A&I)"
    track_desc = "Analytics & Informatics, including BHI (A&I)"
  when "(BCX)"
    track_desc = "Brand & Consumer Experience (BCX)"
  when "(BOE)"
    track_desc = "Business & Operational Excellence (BOE)"
  when "(COMM)"
    track_desc = "Strategic Communications (COMM)"
  when "(DII)"
    track_desc = "Development, Innovation & International (DII)"
  when "(BMC)"
    track_desc = "Brand, Marketing & Communications (BMC)"
  when "(CM)"
    track_desc = "Commercial Markets, including National Programs (CM)"
  when "(C&E)"
    track_desc = "Compliance & Ethics (C&E)"
  when "(CCC)"
    track_desc = "Customer Contact Center & Claims (CCC)"
  when "(D&I)"
    track_desc = "Development & Innovation (D&I)"
  when "(DS)"
    track_desc = "Data Solutions (Quality, Access & Governance) (DS)"
  when "(EIT)"
    track_desc = "Enterprise Information Technology (EIT)"
  when "(IT)"
    track_desc = "Enterprise Information Technology (EIT)"
  when "(EPMO)"
    track_desc = "Enterprise Program Management Office (EPMO)"
  when "(ERM)"
    track_desc = "Enterprise Risk Management (ERM)"
  when "(FAU)"
    track_desc = "Finance, Actuarial & Underwriting (FAU)"
  when "(FIN)"
    track_desc = "Finance (FIN)"
  when "(GP)"
    track_desc = "Government Programs (FEP, Medicare & Medicaid) (GP)"
  when "(HR)"
    track_desc = "Human Resources & Learning (HR)"
  when "(ISP)"
    track_desc = "Information Security & Privacy (ISP)"
  when "(IA)"
    track_desc = "Internal Audit (IA)"
  when "(LAW)"
    track_desc = "Lawyers & Legal Assistants (LAW)"
  when "(NEBA)"
    track_desc = "National Employee Benefits Administration (NEBA)"
  when "(NS)"
    track_desc = "Network Solutions (Development, Execution & Provider Engagement)(NS)"
  when "(OCA)"
    track_desc = "Office of Clinical Affairs (OCA)"
  when "(OPR)"
    track_desc = "Office of Policy & Representation (OPR)"
  when "(P&C)"
    track_desc = "Privacy & Cybersecurity (P&C)"
  when "(SM)"
    track_desc =  "Strategy & Marketing (SM)"
  when "(SBD)"
    track_desc = "Strategy & Business Development (SBD)"
  when "(ALL)"
    track_desc = "All Audiences (ALL)"
  else
    track_desc = track_desc
    @missing_conversions << track_desc
  end
  track_desc
end

def collect_session_tags_from_data(session, ar_session)
  if session["tracks"].is_a?(Array) then
    puts "tracks: #{session["tracks"]}"
    tracks_array = session["tracks"]
    keyword_1 = ""
    keyword_2 = ""
    primary_audience = ""
    secondary_audience = ""
    bcbs_only = ""
	  custom_filter_3 = ""
	  promotion = ""

    tracks_array.each do |track|
      track_name = track["track"]
      track_desc = track["desc"]

      if track_desc != nil then
        if track_name == "Content Theme"
          keyword_1 = "#{track_desc}"
           keyword_1 = return_sanitize_for_db(keyword_1)
        elsif track_name == "Continuing Education"
           keyword_2 += "#{track_desc}"
           keyword_2 = return_sanitize_for_db(keyword_2)
	      elsif track_name =="Primary Audience"
           track_desc = return_full_audience_name(track_desc)
		       primary_audience += "#{track_desc}"
		    elsif track_name =="Secondary Audience"
           track_desc = return_full_audience_name(track_desc)
           if secondary_audience.empty?
            secondary_audience += "#{track_desc}"
           end
        #elsif track_name =="Target Audience 1"
         #  track_desc = return_full_audience_name(track_desc)
          # primary_audience += "#{track_desc}"
        #elsif track_name =="Target Audience 2"
         #  track_desc = return_full_audience_name(track_desc)
          # if secondary_audience.empty?
           # secondary_audience += "#{track_desc}"
           #end
        elsif track_name == "BCBS Only"
            if track_desc == "Yes"
              bcbs_only += "BCBS Plan Only"
            end
 		    elsif track_name == "Content Theme"
              custom_filter_3 = track_desc
		    elsif track_name == "Continuing Education"
              promotion = track_desc
        else
          puts "missing trackname: #{track_name}"
        end
      end
    end
    if primary_audience == secondary_audience
      secondary_audience = ""
    end
  end

  #tags_safeguard = [keyword_1,keyword_2,primary_audience,secondary_audience].join('^^')
  tags_safeguard = [primary_audience,secondary_audience].join('^^')
  
  puts tags_safeguard

  track_subtrack = ""

  #split out the session tagsets for primary audience
  session_tags1 = primary_audience.split('^^').map { |a| a.strip }
  session_tags1.each_with_index do |item,i|
    session_tags1[i] = item.split('||').map { |a| a.strip  }
    item.split('||').each { |a| track_subtrack += "<b>Primary Audience:</b> #{a.strip}<br>" }
  end

  #split out the session tagsets for secondary audience
  session_tags2 = secondary_audience.split('^^').map { |a| a.strip }
  session_tags2.each_with_index do |item,i|
    session_tags2[i] = item.split('||').map { |a| a.strip }
    item.split('||').each { |a| track_subtrack += "<b>Secondary Audience:</b> #{a.strip}<br>" }
  end

  track      = keyword_1
  subtrack   = keyword_2
  tag_type_id  = TagType.where(name:'session').first.id
  session_tags3 = []
  session_tags3 << "Keywords" #nest under keywords tag
  session_tags3 << track       unless track.blank?
  session_tags3 << subtrack    unless subtrack.blank?

  ## addSessionTags expects an array of tagsets, so put our only tagset into an array.
  session_tags3 = [] << session_tags3
  puts "session_tags: #{session_tags3}"
  ar_session.update_tags session_tags3, 'session'

  unless track.blank? && subtrack.blank?
    track_field = track.blank? ? '' : "#{track}"
    subtrack_field = subtrack.blank? ? '' : "#{subtrack}"
    if subtrack.blank?
      line_break = ''
    else
      line_break = "||"
    end
    track_subtrack += "#{track_field} #{line_break} #{subtrack_field}"
  end

  # removing code for BCBS only session tags
  session_tags4 = bcbs_only.split('^^').map { |a| a.strip }
  session_tags4.each_with_index do |item,i|
    session_tags4[i] = item.split('||').map { |a| a.strip }
    item.split('||').each { |a| track_subtrack += "#{a.strip}<br>" }
  end

  track_subtrack = track_subtrack.chomp '<br>'

  #adding custom filters
  if bcbs_only.length > 0 then
    custom_filter_1 = "Blue Plan Attendee"
    custom_filter_2 = "Blue Plan Only"
    premium_access  = true
  else
    custom_filter_1 = nil
    custom_filter_2 = nil
    premium_access = ""
  end
  ar_session.update!(track_subtrack:track_subtrack, custom_filter_1:custom_filter_1, custom_filter_2:custom_filter_2, custom_filter_3:custom_filter_3, promotion:promotion, tags_safeguard:tags_safeguard, premium_access:premium_access, wvctv:wvctv)
  return session_tags1, session_tags2
end

def collect_session_tags_from_data_v2(session, ar_session)
  tags_array = []
  if session['tracks'].is_a?(Array)
    #puts session['tracks']
    tracks_array = session['tracks']
    tracks_array.each do |track|
      track_name = track['track']
      track_desc = track['desc']
      next if track_name.blank?
      next unless track_name.eql?('Primary Audience') || track_name.eql?('Secondary Audience')
      track_desc = return_full_audience_name(track_desc)
      track_desc = '-All Audiences-' if track_desc.eql?('All Audiences')
      tags_array.push([track_desc])
    end
  end
  tags_array
end

def collect_session_audience_tags_from_data(session, ar_session)
  tags_array = []
  premium_access = false
  custom_field_value = nil
  wvctv = nil
  if session['tracks'].is_a?(Array)
    tracks_array = session['tracks']
    tracks_array.each do |track|
      track_name = track['track']
      track_desc = track['desc']
      next if track_name.blank?
      next if track_name.eql?('Primary Audience') || track_name.eql?('Secondary Audience')
      premium_access = track_name.eql?("BCBS Only") && track_desc.eql?('Yes')
      wvctv = wvctv = track_name.eql?("Record") && track_desc.eql?('Yes')
      track_name = 'CPE GROUP' if track_name.eql?('CE ONLY')
      custom_field_value = track_desc if track_name.eql?('Continuing Education')
      tags_array.push([track_name, track_desc])
    end
  end
  ar_session_custom_fields = JSON.load(ar_session.custom_fields)
  ar_session_custom_fields[0]['value'] = custom_field_value
  ar_session.update!(premium_access: premium_access, custom_fields: ar_session_custom_fields.to_json, wvctv:wvctv)
  tags_array
end

def update_track_subtrack(session, ar_session)
  track_hash = {}
  bcbs_only = false
  custom_filter_1 = ""
  custom_filter_2 = ""
  premium_access = false

  def generate_track_string(track_hash, track_name)
    track_subtrack = track_hash[track_name]&.inject("") do |acc, track_desc|
      acc += "<b>#{track_name}:</b> #{track_desc}<br/>"
    end
    track_subtrack || ""
  end

  if session['tracks'].is_a?(Array)
    session['tracks'].each do |track|
      track_name = track['track']
      track_desc = track['desc']
      if track_name.eql?('BCBS Only') && track_desc.eql?('Yes')
        bcbs_only = true
        custom_filter_1 = "Blue Plan Attendee"
        custom_filter_2 = "Blue Plan Only"
        premium_access = true
        next
      end
      track_hash[track_name] = [] unless track_hash.include?(track_name)
      track_hash[track_name].push(track_desc)
    end
  end
  track_subtrack = generate_track_string(track_hash, 'Primary Audience') + 
    generate_track_string(track_hash, 'Secondary Audience') +
    generate_track_string(track_hash, 'Content Theme') + 
    generate_track_string(track_hash, 'Continuing Education')
  
  track_subtrack += 'BCBS Plan Only<br/>' if bcbs_only

  track_subtrack = track_subtrack.chomp '<br/>'
  ar_session.update! track_subtrack: track_subtrack
  ar_session.update! custom_filter_1:custom_filter_1
  ar_session.update! custom_filter_2:custom_filter_2
  ar_session.update! premium_access:premium_access
end

def return_speakers_attribute_hash(speaker)
  #Add speaker codes and event_ids to Speaker table and SessionsSpeaker table. Other speaker information is updated via import-speakers-bcbs2019 script.
  speaker_code         = speaker["pid"]
  published            = speaker["published"]
  speaker_type_id = SpeakerType.where("lower(speaker_type) = ?", speaker['role'].downcase).first_or_create.id

  speaker_attrs = {event_id:@event_id,
    speaker_code:speaker_code,
    speaker_type_id: speaker_type_id,
    first_name: speaker['fname'],
    last_name: speaker['lname'],
    email: speaker['email'],
    city: speaker['city'],
    country: speaker['country'],
    state: speaker['state'],
    company: speaker['company'],
    title: speaker['title'],
    honor_suffix: speaker['suffix'],
    honor_prefix: speaker['honorific']
  }
end

def create_or_update_speaker_and_return_ar_object(speaker_attrs)
  speaker_code = speaker_attrs[:speaker_code]
  ar_speakers = Speaker.where(speaker_code:speaker_code,event_id:@event_id)
  
  if (ar_speakers.length==0) then
    puts "creating speaker"
    ar_speaker = Speaker.new(speaker_attrs)
    ar_speaker.save!
  elsif (ar_speakers.length==1)
    puts "updating speaker"
    ar_speaker = ar_speakers[0]
    ar_speaker.update!(speaker_attrs)
  end
  ar_speaker
end

def create_session_speaker_associations(ar_session, ar_speaker, speaker)
  published = speaker["published"]
  
  if published == true then
    unpublished = false
  else
    unpublished = true
  end

  session_speaker_attrs = {session_id:ar_session.id,speaker_id:ar_speaker.id, unpublished:unpublished, speaker_type_id: ar_speaker.speaker_type_id}

  session_speaker_r = SessionsSpeaker.where(session_id:ar_session.id,speaker_id:ar_speaker.id)
  if (session_speaker_r.length==0) then
    ss_result = SessionsSpeaker.new(session_speaker_attrs)
    ss_result.save!
  elsif (session_speaker_r.length==1)
    ss_result = session_speaker_r[0]
    ss_result.update!(session_speaker_attrs)
  end
end

def update_session_tags(ar_session, session_tags1, session_tags2)
  tag_type_id = TagType.where(name:'session').first.id
  
  all_session_tags = session_tags1 + session_tags2
  ar_session.update_tags all_session_tags, 'session'
end

def update_custom_filter(ar_speakers)
  #for each speaker, if all sessions
  #they are presenting at match custom_filter_1 (Blue Plan)
  #then set the custom_filter_1 field in the speaker row to
  #prevent it showing up in the app when those sessions are filtered out

  ar_speakers.each do |speaker|
    if speaker.sessions.any? {|s| s.custom_filter_1 != "Blue Plan Attendee"}
      speaker.update! custom_filter_1: nil
    else
      speaker.update! custom_filter_1: 'Blue Plan Attendee'
    end
  end
end

def tagset_verification(ar_sessions)
  tag_type_id = TagType.where(name:'session').first.id

  ar_sessions.each do |session|
    if (session.tags_safeguard!=nil) then
      verifySessionTagsV2(session.tags_safeguard,tag_type_id,@event_id,session.session_code)
    end
  end
end

def letter?(letter)
  (letter =~ /[[:alpha:]]/) === 0 ? true : false
end

# this isn't needed at all if we have unpublished working
# def remove_speaker_session_associations(event_id)
#   speaker_ids = Speaker.where(event_id:event_id).pluck(:id)
#   SessionsSpeaker.where(speaker_id:speaker_ids).each do |ss|
#     # TODO: this letter check should not happen for bcbs;
#     # probably was copied over from AVMA
#     ss.delete unless letter?(ss.session.session_code[0])
#   end
# end

ActiveRecord::Base.establish_connection(:adapter => "mysql2",:host => @db_host,:username => @db_user,:password => @db_pass,:database => @db_name)

planstone_url = 'https://static.planion.com/feed/v1/sessions?where=%7B%22account%22%3A%22BCBSNS%22%2C%22conference%22%3A%22NM22%22%7D'


@event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'Planstone API', row:0, status:'In Progress')
end

if JOB_ID && @event_id

  job.start {
    @missing_conversions = []
    @api_session_ids = []
    uri = URI(planstone_url)

    total_records, total_pages = get_total_records(uri)
    page = 1

    while page <= total_pages

      job.status  = 'Fetching data from API'
      job.write_to_file
      page_url = "&page=#{page}"

      sessions_url = planstone_url + page_url
      uri = URI(sessions_url)
      parsed_url = authenticate_api(uri)
      sessions = parsed_url["_items"]
      puts sessions

      job.update!(total_rows:total_records, status:'Processing Rows')
      job.write_to_file

      sessions.each do |session|

        job.row    = job.row + 1
        job.write_to_file if job.row % job.rows_per_write == 0

        session_attrs = return_sessions_attribute_hash(session)
        ar_session = create_or_update_session_and_return_ar_object(session_attrs)
        if session["tracks"].any?
          # session_tags1, session_tags2 = collect_session_tags_from_data(session, ar_session)
          # update_session_tags(ar_session, session_tags1, session_tags2)
          ar_session.update_tags collect_session_tags_from_data_v2(session, ar_session), 'session'
          ar_session.update_tags collect_session_audience_tags_from_data(session, ar_session), 'session-audience'
          update_track_subtrack(session, ar_session)
        else
          puts "empty: #{session["tracks"]}"
        end
        if session["speakers"].is_a?(Array) then
          speakers = session["speakers"]
          speakers.each do |speaker|

            speaker_attrs = return_speakers_attribute_hash(speaker)
            ar_speaker = create_or_update_speaker_and_return_ar_object(speaker_attrs)
            #update SessionsSpeaker only if role is presenter or primary presenter
            if speaker["role"] == "Primary Presenter" || speaker["role"] == "Presenter" || speaker["role"] == "OCA Primary Presenter" || speaker["role"] == "OCA Presenter"
              create_session_speaker_associations(ar_session, ar_speaker, speaker)
            end

          end
        end
      end
      ar_sessions = Session.where(event_id:@event_id)
      ar_speakers = Speaker.where(event_id:@event_id)
      update_custom_filter(ar_speakers)
      tagset_verification(ar_sessions)
      page +=1 #important to avoid infinite loop
      puts page
    end

    job.status  = 'Cleanup'
    job.write_to_file
    #Remove sessions that did not appear in their refresh
    session_codes = Session.where(event_id:@event_id).pluck(:session_code)
    unless @api_session_ids.empty?
      session_codes_to_destroy = session_codes - @api_session_ids
      puts "----- destroying session_codes for event #{@event_id}: #{session_codes_to_destroy} --------"
      Session.where(event_id:@event_id, session_code:session_codes_to_destroy).destroy_all
    end
    puts "missing name conversion: #{@missing_conversions}"

  } #job.start
else
  #terminal version

  @event_id = 304
  @api_session_ids = []
  uri = URI(planstone_url)

  total_records, total_pages = get_total_records(uri)
  page = 1

  while page <= total_pages

    page_url = "&page=#{page}"

    sessions_url = planstone_url + page_url
    uri = URI(sessions_url)
    parsed_url = authenticate_api(uri)
    sessions = parsed_url["_items"]

    sessions.each do |session|

      session_attrs = return_sessions_attribute_hash(session)
      ar_session = create_or_update_session_and_return_ar_object(session_attrs)
      if session["tracks"].any?
        # session_tags1, session_tags2 = collect_session_tags_from_data(session, ar_session)
        # update_session_tags(ar_session, session_tags1, session_tags2)
        ar_session.update_tags collect_session_tags_from_data_v2(session, ar_session), 'session'
        ar_session.update_tags collect_session_audience_tags_from_data(session, ar_session), 'session-audience'
        update_track_subtrack(session, ar_session)
      else
        puts "empty: #{session_tracks}"
      end
      if session["speakers"].is_a?(Array) then
        speakers = session["speakers"]
        speakers.each do |speaker|

          speaker_attrs = return_speakers_attribute_hash(speaker)
          ar_speaker = create_or_update_speaker_and_return_ar_object(speaker_attrs)
          #update SessionsSpeaker only if role is presenter or primary presenter
          if speaker["role"] == "Primary Presenter" || speaker["role"] == "Presenter" || speaker["role"] == "OCA Primary Presenter" || speaker["role"] == "OCA Presenter"
            create_session_speaker_associations(ar_session, ar_speaker, speaker)
          end

        end
      end
    end
    ar_sessions = Session.where(event_id:@event_id)
    ar_speakers = Speaker.where(event_id:@event_id)
    update_custom_filter(ar_speakers)
    tagset_verification(ar_sessions)
    page +=1 #important to avoid infinite loop
  end

  #Remove sessions that did not appear in their refresh
  session_codes = Session.where(event_id:@event_id).pluck(:session_code)
  unless @api_session_ids.empty?
    session_codes_to_destroy = session_codes - @api_session_ids
    puts "session_codes: #{session_codes}"
    puts "to delete: #{@api_session_ids}"
    puts "final list: #{session_codes_to_destroy}"
    puts "----- destorying session_codes for event #{@event_id}: #{session_codes_to_destroy} --------"
    Session.where(event_id:@event_id, session_code:session_codes_to_destroy).destroy_all
  end
end


