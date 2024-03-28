# combined script for BCBSA Women's Leadership Conference and HOA
require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'

@missing_sessions = []
@all_sessions = []

def apiFetch_BCBS(url)
  uri = URI(url)

  Net::HTTP.start(uri.host, uri.port, :read_timeout => 25000,
  :use_ssl => uri.scheme == 'https') do |http|

    request = Net::HTTP::Get.new uri.request_uri
    
    response = http.request request # Net::HTTPResponse object

    url = response.body
    return url
  end

end


def return_attendee_attributes_hash(attendee, event_id)

  def return_type_id(type_name)
		types = AttendeeType.where(name:type_name);	types.length==1 ? types[0].id : nil;
	end

  def process_custom_fields(fields)
    primary_name = ""
    secondary_name = ""
    company_name = ""
    fields.each do |f|
      case f["@field_name"]
      when "Company Name"
        primary_name = f["@field_value"]
      when "Company (other than Blue Plan)"
        secondary_name = f["@field_value"]
      end
    end
    unless primary_name.blank? || primary_name == "Other (please enter company name in Other Company field below)"
      company_name = primary_name
    else
      company_name = secondary_name
    end
    company_name
  end

  def clean_up_name(company_name)
    company_name = company_name.strip
    if company_name.length < 4
      company_name = ""
    end
    unless company_name.blank?
      company_name.gsub!('Cros ','Cross ')
      company_name.gsub!('Bue','Blue')
      company_name.gsub!('Shields','Shield')
      company_name.gsub!('Northestern', 'Northeastern')
      company_name.gsub!('Rein,', 'Rein')
    end
    company_name
  end

  business_unit    = attendee["business_unit"].nil? ? '' : attendee["business_unit"].gsub(/\u0026/,"&")
  attendee_type_id = return_type_id(attendee["registration_type"])
  # company_name     = process_custom_fields(attendee["custom_field_detail"])
  # if company_name.blank?
  #   company_name = attendee["company"]
  # end

	{event_id:         event_id,
	 account_code:     attendee["account_code"],
	 first_name:       attendee["first_name"],
	 last_name:        attendee["last_name"],
	 title:            attendee["title"],
	 email:            attendee["email_address"],
	 username:         attendee["email_address"],
	 #password:         attendee["work_postal_code"],
	 custom_filter_1:  attendee["registration_type"],
	 attendee_type_id: attendee_type_id,
	 company:          attendee["company"],
	 messaging_opt_out:   false,
	 app_listing_opt_out: false,
	 game_opt_out:        false,
	 business_unit:    "",
 }
end

def return_attendee_rows(attendee_attrs)
	Attendee.where(account_code:attendee_attrs[:account_code],event_id:attendee_attrs[:event_id])
end

# def add_prefavourites(attendee_id)
# 	PREFAVOURITES.each {|p|
# 		SessionsAttendee.where(attendee_id:attendee_id, flag:'cms_external_api', session_id:p[:session_id], session_code:p[:session_code]).first_or_create }
# end

def create_or_update_attendee_with_msg(attendee_attrs)

	rows           = return_attendee_rows(attendee_attrs)
	create_message = "--- creating attendee: #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]} ---\n".green
	update_message = "---- updating attendee: #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]} ----\n".yellow
	error_message  = "ERROR: Multiple rows for attendee #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]}".red

	if rows.length == 0
		msg = create_message
		Attendee.create(attendee_attrs)
	elsif rows.length == 1
		msg = update_message
		rows[0].update!(attendee_attrs)
	else
		msg = error_message
	end
end

def create_or_update_attendee(attendee_attrs)
	attendee = return_attendee_rows(attendee_attrs)
											 .first_or_initialize
	attendee.update!(attendee_attrs)
	attendee
end



def remove_attendee(attendee_attrs)
	rows           = return_attendee_rows(attendee_attrs)
	delete_message = "--- deleted cancelled attendee: #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]} ---\n".green
	error_message  = "ERROR: Multiple rows for attendee #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]}, did not delete cancelled attendee".red

	if rows.length == 1
		msg = delete_message
		rows[0].destroy
	elsif rows.length > 1
		msg = error_message
	end
end

def return_plan_tagset_array(attendee_attrs)
	['BCBS Plan/Company', attendee_attrs[:custom_filter_1], attendee_attrs[:company]]
end

def return_business_dicipline_tagset_array(attendee_attrs)
	['Business Discipline', attendee_attrs[:business_unit]]
end

# def return_title_tagset_array(attendee_attrs)
# 	['Title', attendee_attrs[:title]]
# end

def return_attendee_tag_array(attendee_attrs)
	tag_array = []
	tag_array << return_plan_tagset_array(attendee_attrs) unless attendee_attrs[:custom_filter_1].blank? || attendee_attrs[:company].blank?
	tag_array << return_business_dicipline_tagset_array(attendee_attrs) unless attendee_attrs[:business_unit].blank?
	#not including title tags as tagset too random
	# tag_array << return_title_tagset_array(attendee_attrs)              unless attendee_attrs[:title].blank?
	tag_array
end

def return_tags_safeguard(attendee_tag_array)

	def end_of_array?(index, array)
		(index+1)===array.length
	end

	tags_safeguard = ''

	if attendee_tag_array.length > 0
		attendee_tag_array.each_with_index do |tag_group, i|
			tag_group.each_with_index {|t, i| tags_safeguard += end_of_array?(i, tag_group) ? t : "#{t}||" }
			tags_safeguard += '^^' unless end_of_array?(i, attendee_tag_array)
		end
	end
	tags_safeguard
end

def create_or_update_attendee_sessions(attendee, ar_attendee, event_id)
  def get_assigned_sessions(ar_attendee)
    sessions_array =[]
    if ar_attendee.custom_fields_3 == "3.0"
      sessions_array = ["HOA01A", "HOA01B", "HOA01C", "HOA01D", "HOA03", "HOA04", "HOA05", "HOA06", "HOA07", "HOA08", "HOA09", "HOA10", "HOA11", "HOA13A", "HOA13B", "HOA13C", "HOA13D", "HOA15", "HOA16", "HOA17", "HOA18", "HOA19", "HOA20", "HOA21", "HOA22", "HOA23", "HOA24"]
    elsif ar_attendee.custom_fields_3 == "1.0"
      sessions_array = ["HOA01A", "HOA01B", "HOA01C", "HOA01D", "HOA03", "HOA04", "HOA05", "HOA06", "HOA07", "HOA08", "HOA09", "HOA10", "HOA11"]
    elsif ar_attendee.custom_fields_3 == "2.0"
      sessions_array = ["HOA13A", "HOA13B", "HOA13C", "HOA13D", "HOA15", "HOA16", "HOA17", "HOA18", "HOA19", "HOA20", "HOA21", "HOA22", "HOA23", "HOA24"]
    else 
      puts "missing attendee #{ar_attendee.last_name}"
      puts ar_attendee.custom_fields_3
      sessions_array = []
    end
    sessions_array
  end

  attendee_id       = ar_attendee.id
  old_sessions      = SessionsAttendee.where(attendee_id:attendee_id, flag:"web")
  # old_sessions.delete_all
  assigned_sessions = get_assigned_sessions(ar_attendee)
  assigned_sessions.each do |s_code|
    sessions = Session.where(session_code:s_code, event_id:event_id)
    if sessions.length > 1
      sessions.each do |session|
        session_attendee = SessionsAttendee.where(session_id:session.id, attendee_id:attendee_id).first_or_initialize
        session_attendee.update!(session_code:session.session_code,flag:"web")
      end
    elsif sessions.length == 1
      session = sessions.first
      session_attendee = SessionsAttendee.where(session_id:session.id, attendee_id:attendee_id).first_or_initialize
      session_attendee.update!(session_code:session.session_code,flag:"web")
    else
      # puts "missing session"
      @missing_sessions << s_code
    end
  end
end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)



HOST          = 'https://bcbsproxyb.eventkaddy.net'
# HOST            = 'http://localhost:3001'

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

    url = HOST + '/attendeedata_bcbs_hoa_2020?proxy_key=' + MERCURY_CREDS
		attendees     = JSON.parse(apiFetch_BCBS(url))
    puts attendees

		tag_type_id   = TagType.where(name:'attendee').pluck(:id).first

		job.update!(total_rows:attendees.length, status:'Processing Rows')
		job.write_to_file
    job.row = 0

		attendees.each do |attendee|

			job.row    = job.row + 1
			job.write_to_file 

			attendee_attrs                  = return_attendee_attributes_hash(attendee, event_id)
			attendee_tag_array              = return_attendee_tag_array(attendee_attrs)
			attendee_attrs[:tags_safeguard] = return_tags_safeguard(attendee_tag_array)

			unless attendee["cancelled"]
				create_or_update_attendee_with_msg(attendee_attrs)
				ar_attendee = create_or_update_attendee(attendee_attrs)
        create_or_update_attendee_sessions(attendee, ar_attendee, event_id)
				ar_attendee.update_tags attendee_tag_array, 'attendee'
			else
				remove_attendee(attendee_attrs)
			end
		end #attendees loop

		job.status  = 'Cleanup'
		job.write_to_file
    puts "missing sessions: #{@missing_sessions.uniq}"
    puts "all sessions: #{@all_sessions.uniq}"

		Attendee.where(event_id:event_id).each do |a|
			verifyAttendeeTags(a.tags_safeguard, tag_type_id, event_id, a.account_code) if a.tags_safeguard!=nil
		end
	}
end

