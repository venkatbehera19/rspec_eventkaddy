require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'


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



def fetchAttendees(token, token_expires_at, page)
	url = URI("https://www.swoogo.com/api/v1/registrants.json?event_id=58523&fields=email,prefix,first_name,middle_name,last_name,suffix,company,job_title,work_phone,mobile_phone,bio,twitter_handle,id,session_ids&expand=&search=&page=#{page}&per-page=200&sort")

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

def fetchAllAttendees(token, token_expires_at, page, total_page, attendees_arr)
	if page <= total_page
		getAttendees = fetchAttendees(token, token_expires_at, page)
		page += 1
		total_page = getAttendees["_meta"]["pageCount"]
		attendees_arr << getAttendees["items"]
		fetchAllAttendees(token, token_expires_at, page, total_page, attendees_arr, )
	end
	attendees_arr.flatten
end


def return_attendee_attributes_hash(attendee, event_id)

  def clean_up_mobile(mobile)
    mobile = mobile.strip.gsub('-','').gsub('(','').gsub(')','').gsub('.','').gsub(' ','').gsub('+','')
    if mobile.length > 10
      country_code = mobile[0]
      mobile = mobile[1..10]
    else
      country_code = 1
    end
    return mobile, country_code
  end

	attendance_focus=''
	if !attendee["bio"].blank? && attendee["bio"].length > 0
		attendance_focus = attendee["bio"].gsub(/\u0026/,"&")
	end
 
  mobile, country_code = clean_up_mobile(attendee["mobile_phone"])

  twitter_url = attendee["twitter_handle"].blank? ? nil : attendee["twitter_handle"]

  job_title = attendee["job_title"].blank? ? nil : "Job Title: #{attendee["job_title"]}"

	{event_id:         event_id,
	 account_code:     attendee["id"],
	 first_name:       attendee["first_name"],
	 last_name:        attendee["last_name"],
	 title:            attendee["suffix"],
	 email:            attendee["email"],
	 username:         attendee["email"],
	 password:         "Inspire22",
	 company:          attendee["company"],
	 mobile_phone:  mobile,
   business_phone:  attendee["work_phone"],
   custom_fields_3:  country_code,
	 messaging_opt_out:   false,
	 app_listing_opt_out: false,
	 game_opt_out:        false,
	 custom_fields_1:  job_title,
   twitter_url:      twitter_url}
end

def return_attendee_rows(attendee_attrs)
	Attendee.where(account_code:attendee_attrs[:account_code],event_id:attendee_attrs[:event_id])
end

def create_or_update_attendee_with_msg(attendee_attrs)

	rows           = return_attendee_rows(attendee_attrs)
	create_message = "--- creating attendee: #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]} ---\n".green
	update_message = "---- updating attendee: #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]} ----\n".yellow
	error_message  = "ERROR: Multiple rows for attendee #{attendee_attrs[:account_code]} #{attendee_attrs[:first_name]}".red

	if rows.length == 0
		msg = create_message
		attendee = Attendee.create(attendee_attrs)
	elsif rows.length == 1
		msg = update_message
		rows[0].update!(attendee_attrs)
		attendee = rows[0]
	else
		msg = error_message
	end
	attendee
	# puts msg
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

	# puts msg
end

def return_plan_tagset_array(attendee_attrs)
	[attendee_attrs[:company], attendee_attrs[:custom_fields_1].split("Job Title:")[1].strip]
end

def return_attendee_tag_array(attendee_attrs)
	tag_array = []
	tag_array << return_plan_tagset_array(attendee_attrs) unless attendee_attrs[:custom_fields_1].blank? || attendee_attrs[:company].blank?
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

def create_sessions_attendee(attendee, event_id)
	session_codes = attendee["session_ids"]
	account_code = attendee["id"]
	attendee = Attendee.find_by(event_id: event_id, account_code: account_code)
	sessions = Session.where(event_id: event_id, session_code: session_codes)
	if attendee.present? && sessions.present?
		sessions.each do |session|
			SessionsAttendee.find_or_create_by(attendee_id: attendee.id, session_id: session.id.to_s, session_id_int: session.id, flag: "web", session_code: session.session_code)
		end
	end
end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host: @db_host,username: @db_user,password: @db_pass,database: @db_name)

event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'SWOOGO API', row:0, status:'In Progress')
end

if JOB_ID && event_id

	job.start {

		job.status  = 'Fetching data from API'
		job.write_to_file
		auth     = apiFetchAuthSwooho
		token    = auth["access_token"]
		token_expires_at = auth["expires_at"] #in utc
		fetch_attendees = fetchAllAttendees(token, token_expires_at, 1, 1, [])
		job.update!(total_rows:fetch_attendees.length, status:'Processing Rows')
		job.write_to_file
		fetch_attendees.each do |attendee|
			job.row    = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			attendee_attrs                  = return_attendee_attributes_hash(attendee, event_id)
			attendee_tag_array              = return_attendee_tag_array(attendee_attrs)
			attendee_attrs[:tags_safeguard] = return_tags_safeguard(attendee_tag_array)

			ar_attendee = create_or_update_attendee_with_msg(attendee_attrs)
			# ar_attendee = create_or_update_attendee(attendee_attrs)

			ar_attendee.update_tags attendee_tag_array, 'attendee'
			create_sessions_attendee(attendee, event_id)
		end

		job.status  = 'Cleanup'
		job.write_to_file
	}
end