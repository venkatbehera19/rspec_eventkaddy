require 'net/http'
require 'open-uri'
require 'active_record'
require 'timeout'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'

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


def return_attendee_attributes_hash(attendee, pn_filter_processor, event_id)

  def return_type_id(type_name)
		#types = AttendeeType.where(name:type_name);	#types.length==1 ? types[0].id : nil;
		types = nil
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

  business_unit    = attendee["business_unit"].nil? ? '' : attendee["business_unit"].gsub(/\u0026/,"&")

	attendance_focus=''
	if !attendee["biography"].blank? && attendee["biography"].length > 0
		attendance_focus = attendee["biography"].find{|k| k.keys.include?("attendance_focus")}
		attendance_focus = attendance_focus.nil? ? '' : attendance_focus.gsub(/\u0026/,"&")
	end

	camelized_attendance_focus = ""
	attendance_focus.split('/').each do |filter|
		filter=filter.split.map(&:capitalize).join(' ')
		filter.gsub!(' ','')
		filter = filter.camelize(:lower)
		camelized_attendance_focus=camelized_attendance_focus+filter+'/'
	end
 	attendance_focus = camelized_attendance_focus.chop

  attendee_type_id = return_type_id(attendee["registration_type"])
  company_name     = process_custom_fields(attendee["custom_field_detail"])
  if company_name.blank?
    company_name = attendee["company"]
  end

  # processed_filters = pn_filter_processor.process_filters(
  #   business_unit,
  #   nil
  # )

	processed_filters = pn_filter_processor.process_filters(
    "",
    attendance_focus
  )

  pn_filters = unless processed_filters[:updated_filters].blank?
                 processed_filters[:updated_filters].to_s
               else
                 nil
               end

  if attendee["registration_type"] == "Exhibitor Lead Retrieval"
  #if attendee["registration_type"].include? "Retrieval"
 	  #attendee_type_id = AttendeeType.find_by(name: "Exhibitor").id
	attendee_type_id = 4
  end
 
 mobile, country_code = clean_up_mobile(attendee["mobile_phone"])

	if attendee["registration_type"] == "Exhibitor Lead Retrieval"
	  attendee_type_id = AttendeeType.find_by(name: "Exhibitor").id
	end
	
	{event_id:         event_id,
	 #account_code:     attendee["account_code"],
	 account_code:     attendee["confirmation_number"],
	 first_name:       attendee["first_name"],
	 last_name:        attendee["last_name"],
	 title:            attendee["title"],
	 email:            attendee["email_address"],
	 username:         attendee["email_address"],
	 password:         attendee["work_postal_code"],
	 custom_filter_1:  attendee["registration_type"],
	 #custom_filter_3:  attendee["confirmation_number"],
	 custom_filter_2:  attendee["account_code"],
	 custom_filter_3:  nil,
	 attendee_type_id: attendee_type_id,
	 company:          clean_up_name(company_name),
	 # speaker_biography:attendee["biography"],
	 custom_fields_1:  mobile,
   custom_fields_2:  attendee["mobile_phone"],
   custom_fields_3:  country_code,
	 messaging_opt_out:   false,
	 app_listing_opt_out: false,
	 game_opt_out:        false,
	 business_unit:    business_unit, 
     #custom_filter_2:   attendee["photo_url"],
     #custom_filter_2: attendee["attendance_focus"],
   pn_filters:       pn_filters}
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

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)



HOST          = 'https://bcbsproxyb.eventkaddy.net'
# HOST            = 'http://localhost:4567'
attendees_url = HOST + '/attendeedata_bcbs_2022?proxy_key=' + MERCURY_CREDS

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

		attendees     = JSON.parse(apiFetch_BCBS(attendees_url))
    # puts attendees
    # target_path     = Rails.root.join('public', 'event_data', event_id.to_s).to_path
    # FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
    # filename        = "bcbs_attendees2019.json"
    # full_path       = "#{target_path}/#{filename}"
    # file = File.read full_path
    # attendees = JSON.parse(file)
		tag_type_id   = TagType.where(name:'attendee').pluck(:id).first
		# prefavourite_session_codes = [873,874,875,876,877,878,879,880,881,882,883,884,885,886,887,888]
		# PREFAVOURITES = Session.select('id, session_code').where(event_id:event_id,session_code:prefavourite_session_codes).map {|session|
		# 	{session_id:session.id, session_code:session.session_code}}

    pn_filter_processor = PnFilterProcessor.new( event_id )

		job.update!(total_rows:attendees.length, status:'Processing Rows')
		job.write_to_file

		attendees.each do |attendee|

			job.row    = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			attendee_attrs                  = return_attendee_attributes_hash(attendee, pn_filter_processor, event_id)
			attendee_tag_array              = return_attendee_tag_array(attendee_attrs)
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

		Attendee.where(event_id:event_id).each do |a|
			verifyAttendeeTags(a.tags_safeguard, tag_type_id, event_id, a.account_code) if a.tags_safeguard!=nil
		end
    
    #updating premium_member
    premium_member_array = ['Blue Cross Blue Shield Plan Attendee','Blue Cross Blue Shield Plan Speaker', 'BCS/BHI/CHP/NASCO/Prime Therapeutics Attendee','BCS/BHI/Bupa/CHP/GeoBlue/NASCO/Prime Therapeutics','BCS/BHI/Bupa/CHP/GeoBlue/NASCO/Prime Attendee','BCS/BHI/Bupa/CHP/GeoBlue/NASCO/Prime Speaker','BCS/BHI/CHP/NASCO/Prime Therapeutics Speaker','Conference Planning Committee Member','Blue Cross Blue Shield Association Staff']
    attendees = Attendee.where(event_id:event_id)
    attendees.each do |attendee|
      if premium_member_array.include? attendee.custom_filter_1
        #attendee is a premium_member
        attendee.update!(premium_member:true)
      end
    end
	}
end
# else
	## crobtab version

# 	event_id = ??

# 	attendees     = JSON.parse(apiFetch_BCBS(attendees_url))

#   # target_path     = Rails.root.join('public', 'event_data', event_id.to_s).to_path
#   # FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
#   # filename        = "bcbs_attendees2019.json"
#   # full_path       = "#{target_path}/#{filename}"
#   # file = File.read full_path
#   # attendees = JSON.parse(file)

# 	tag_type_id   = TagType.where(name:'attendee').pluck(:id).first
#   pn_filter_processor = PnFilterProcessor.new( event_id )

# 	attendees.each do |attendee|

# 		attendee_attrs                  = return_attendee_attributes_hash(attendee, pn_filter_processor, event_id)
# 		attendee_tag_array              = return_attendee_tag_array(attendee_attrs)
# 		attendee_attrs[:tags_safeguard] = return_tags_safeguard(attendee_tag_array)

# 		unless attendee["cancelled"]
# 			create_or_update_attendee_with_msg(attendee_attrs)
# 			ar_attendee = create_or_update_attendee(attendee_attrs)
# 			ar_attendee.update_tags attendee_tag_array, 'attendee'
# 		else
# 			remove_attendee(attendee_attrs)
# 		end
# 	end

# end

#used for pn filter generation
# business_hash = Hash.new
# @short_codes = []
# @business_units.each do |b|
# short_code = b[/\(.*?\)/]
# short_code = short_code[1..-2]
# business_hash[b]=[short_code]
# @short_code << short_code
# end
# business_hash.as_json
# event = Event.find(event_id)
# event.update! = (type_to_pn_hash:business_hash)
# puts @short_code.uniq
