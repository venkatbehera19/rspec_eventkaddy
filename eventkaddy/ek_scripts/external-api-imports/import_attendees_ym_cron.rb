require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'


puts "Inside #{Dir.pwd}"

def apiFetch_YourMembership(url)
  uri = URI(url)

  Net::HTTP.start(uri.host, uri.port, :read_timeout => 25000,
  :use_ssl => uri.scheme == 'https') do |http|

    request = Net::HTTP::Get.new uri.request_uri
    
    response = http.request request # Net::HTTPResponse object

    url = response.body
    return url
  end

end

def create_job(event_id, refresh, attendee_type)
  job = Job.new(status: "Starting...")
  job.event_id = event_id
  if refresh == "true"
    if attendee_type == "standard_attendee"
      job.name = "refresh-attendees"
    else
      job.name = "refresh-exhibitors"
    end
  else
    if attendee_type == "standard_attendee"
      job.name = "get-attendees"
    else
      job.name = "get-exhibitors"
    end
  end
  job.save!
  return job
end


def return_attendee_attributes_hash(attendee, event_id)

	def clean_up_name(company_name)
    company_name = company_name.strip
    
    unless company_name.blank?
      company_name.gsub!("'","")
    end
    company_name
  end

	if attendee["email"].blank? && attendee["username"].blank?
		attendee["username"] = attendee["first_name"]+"_"+attendee["last_name"]
	end

	custom_filter_3 = nil
	if attendee["Custom_AreyouattendingLiveEquipmentDemonstrationday"].present?
		custom_filter_3 = "AttendingLiveEquipmentDemonstration:#{attendee["Custom_AreyouattendingLiveEquipmentDemonstrationday"]}"
	end
	
	{ 
		event_id:         event_id,	
		first_name:       attendee["first_name"],
	 	last_name:        attendee["last_name"],
	 	title:            attendee["title"],
	 	email:            attendee["email"],
		city:							attendee["city"],
		state:						attendee["state"],
		country:					attendee["country"],
		company:					attendee["company"]!=nil ? clean_up_name(attendee["company"]) : attendee["company"],
		is_member:				attendee["is_member"],
		username:					attendee["username"],
		account_code:     attendee["registration_id"],
		password:					"COMPOST2023",
    custom_filter_3:  custom_filter_3,
		custom_fields_1:  attendee["people_id"]
	}
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
		Attendee.create(attendee_attrs)
	elsif rows.length == 1
		msg = update_message
		rows[0].update!(attendee_attrs)
	else
		msg = error_message
	end

	puts msg
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

def return_company_tagset_array(attendee_attrs)
	unless attendee_attrs[:company].blank?
		['Company', attendee_attrs[:company]]
	else
		['Company', "anonymous"]
	end
end

def return_state_tagset_array(attendee_attrs)
	['State', attendee_attrs[:state]]
end

def return_interest_tagset_array(attendee)
	['Interest', attendee["interests"]]
end

def return_attendee_tag_array(attendee_attrs, attendee)
	tag_array = []
	tag_array << return_company_tagset_array(attendee_attrs)
	tag_array << return_state_tagset_array(attendee_attrs) unless attendee_attrs[:state].blank?
	tag_array << return_interest_tagset_array(attendee) unless attendee["interests"].blank?
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

begin
  ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

  HOST          = 'https://bcbsproxyb.eventkaddy.net'
  # HOST            = 'http://localhost:4567'
  event_id       = ARGV[0]
  refresh        = ARGV[1]
  attendee_type  = ARGV[2]

  attendees_url = HOST + '/attendeedata_your_membership_2023?proxy_key='+MERCURY_CREDS+'&refresh='+refresh+'&attendee_type='+attendee_type

  # create job to input all the information about this process
  job = create_job(event_id, refresh, attendee_type)
  job.update!(original_file:'YourMembership API', row:0, status:'In Progress')
  

  if job && event_id
    job.status  = 'Fetching data from API'
    job.write_to_file
    attendees     = JSON.parse(apiFetch_YourMembership(attendees_url))
    tag_type_id   = TagType.where(name:'attendee').pluck(:id).first
    job.update!(total_rows:attendees.length, status:'Processing Rows')
    job.write_to_file

    attendees.each do |attendee|

      job.row    = job.row + 1
      job.write_to_file if job.row % job.rows_per_write == 0
      
      attendee_attrs                  = return_attendee_attributes_hash(attendee, event_id)
      attendee_tag_array              = return_attendee_tag_array(attendee_attrs, attendee)
      attendee_attrs[:tags_safeguard] = return_tags_safeguard(attendee_tag_array)
      
      unless attendee["cancelled"]
        create_or_update_attendee_with_msg(attendee_attrs)
        ar_attendee = create_or_update_attendee(attendee_attrs)
        ar_attendee.update_tags attendee_tag_array, 'attendee'
      else
        remove_attendee(attendee_attrs)
      end
    end

    job.status  = 'Cleanup'
    job.write_to_file
    job.update!(status: "Completed")
		job.write_to_file

    Attendee.where(event_id:event_id).each do |a|
      verifyAttendeeTags(a.tags_safeguard, tag_type_id, event_id, a.account_code) if a.tags_safeguard!=nil
    end
  end
rescue => e
  if job && !job.errors.any?
    begin
      job.update!(status: 'Failed', error_message: e.message, backtrace: e.backtrace.inspect)
    rescue
      job.update!( status:'Failed', error_message:"error message could not be saved (probably encoding issue)", backtrace:"backtrace could not be saved (probably encoding issue)")
    end
    job.write_to_file
  end
    # send mail notification when the error is caused inside the cron job
    ErrorMailer.external_api_import_mailer(e.message, e.backtrace).deliver_now
    # debug error message and backtrace to the console.
    puts "#{e.message}".red.underline.bold
    puts e.backtrace
end