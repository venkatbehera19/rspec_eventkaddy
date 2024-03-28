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
	url = URI("https://www.swoogo.com/api/v1/registrants.json?event_id=58523&fields=email,id,session_ids&expand=&search=&page=#{page}&per-page=200&sort")

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


ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)


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
		fetch_session_attendees = fetchAllAttendees(token, token_expires_at, 1, 1, [])
		job.update!(total_rows: fetch_session_attendees.length, status:'Processing Rows')
		job.write_to_file
		fetch_session_attendees.each do |attendee|
			job.row    = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			session_attende                  = create_sessions_attendee(attendee, event_id)
		end

		job.status  = 'Cleanup'
		job.write_to_file
	}
end