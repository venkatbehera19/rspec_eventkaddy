require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'


def api_fetch_your_membership_image_uri(url, payload)
	response = []
	# Slicing payload because it is used as HTTP_PARAMS and there is a maximum size we can use 
	return response if payload.blank?
	payload = payload.each_slice(300).to_a
	payload.each do |payload|
		begin
			sliced_response = RestClient::Request.execute(
			method:  :get, 
			url:     url,
			timeout:  nil,
			open_timeout: nil,
			headers: { params: payload, content_type: 'application/json', accept: 'application/json'}
		)
			if sliced_response.code == 200 && !sliced_response.body.nil?
				sliced_response = JSON.parse(sliced_response)
				response << sliced_response
			else
				raise StandardError.new "Failed to fetch the images. Server responsed with #{sliced_response.code}"
			end
		rescue => e
			puts "Inside rescue block with error: #{e.message}".red.underline
		end
	end
response.flatten!
end

def return_attendee_rows(attendee, event_id)
	Attendee.where(custom_fields_1: attendee["people_id"], event_id: event_id)
end

def create_or_update_attendee_with_msg(attendee, event_id)

	rows           = return_attendee_rows(attendee, event_id)
	update_message = "---- updating attendee with with headshot image url: #{attendee["people_id"]} #{attendee["FirstName"]} ----\n".yellow
	error_message  = "ERROR: Multiple rows for attendee #{attendee["people_id"]} #{attendee["FirstName"]}".red

	if rows.length == 1
		msg = update_message

		uploaded_from_app = rows[0].photo_filename.present? && rows[0].photo_filename.include?('olympus-phoenix-rails5.eventkaddy.net')
		uploaded_and_valid_from_ym  = attendee["HeadshotImageURI"].present? && File.extname(attendee["HeadshotImageURI"]) != '.gif'

		if !uploaded_from_app && uploaded_and_valid_from_ym
			puts "--------- updating #{rows[0].id} ---------------------------"
			event_file = EventFile.new(event_id: event_id, path: attendee["HeadshotImageURI"], cloud_storage_type_id: nil, event_file_type_id: 32)
			event_file.save
			rows[0].update!(photo_filename: attendee["HeadshotImageURI"], photo_event_file_id: event_file.id)
		end
	else
		return error_message
	end

	puts msg
end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

HOST          = 'https://bcbsproxyb.eventkaddy.net'
#HOST            = 'http://localhost:4567'


event_id       = ARGV[0]
JOB_ID         = ARGV[1]
attendee_type  = ARGV[3]

attendees_url = HOST + '/attendee_imageURI_your_membership_2023?proxy_key='+MERCURY_CREDS
payload = Attendee.where(event_id: event_id).pluck(:custom_fields_1).as_json(:except => :id).compact

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'YourMembership-FetchImageUrl-API', row:0, status:'In Progress')
end

if JOB_ID && event_id

	job.start {

		job.status  = 'Fetching data from API'
		job.write_to_file

		attendees = api_fetch_your_membership_image_uri(attendees_url, payload)
		job.update!(total_rows:attendees.length, status:'Processing Rows')
		job.write_to_file
		error_messages = []
		attendees.each do |attendee|
			# puts "#{attendee}".magenta.underline
			job.row    = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0
      error_messages << create_or_update_attendee_with_msg(attendee, event_id)
		end
		
		error_messages = error_messages.reject(&:blank?)
		error_messages.each {|error_message| puts error_message} if error_messages.length > 0
			

		job.status  = 'Cleanup'
		job.write_to_file
	}
end
