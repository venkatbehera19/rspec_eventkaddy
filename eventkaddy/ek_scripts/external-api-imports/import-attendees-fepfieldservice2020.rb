#fep
#Field Service Sept 2019
require 'net/http'
require 'open-uri'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require_relative '../../config/initializers/global_constants.rb'

@missing_sessions = []

def return_attendee_attributes_hash(attendee)

  def return_titleized_name(name)
    if name === name.upcase || name === name.downcase
      if name.length > 4
        name = name.titleize
      end
    end
    name
  end

	def return_type_id(type_name)
		types = AttendeeType.where(name:type_name);	types.length==1 ? types[0].id : nil;
	end

  def process_custom_fields(fields)
    primary_name = ""
    secondary_name = ""
    tertiary_name = ""
    company_name = ""
    fields.each do |f|
      case f["@field_name"]
      when "Blue Cross Blue Shield Plan Name"
        company_name =f["@field_value"]
      end
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

	business_unit    = attendee["designation"].nil? ? '' : attendee["designation"].gsub(/\u0026/,"&")
	attendee_type_id = return_type_id(attendee["registration_type"])
  company_name     = process_custom_fields(attendee["custom_field_detail"])
  if company_name.blank?
    company_name = attendee["company"]
  end

	{event_id:         @event_id,
	 account_code:     attendee["account_code"],
	 first_name:       return_titleized_name(attendee["first_name"]),
	 last_name:        return_titleized_name(attendee["last_name"]),
	 title:            return_titleized_name(attendee["title"]),
	 email:            attendee["email_address"],
	 username:         attendee["email_address"],
   #password should not be updated for all fep events
	 custom_filter_3:  attendee["registration_type"],
	 attendee_type_id: attendee_type_id,
	 company:          clean_up_name(company_name),
	 # speaker_biography:attendee["biography"],
   speaker_biography:'',
	# biography:        '',
	 messaging_opt_out:   false,
	 app_listing_opt_out: false,
	 game_opt_out:        false,
	 business_unit:    business_unit,
	 #business_unit:    '',
	 city:    attendee["city"],
   state:    attendee["state"],
   country:    attendee["country"],
   custom_filter_2:  attendee["photo_url"]}
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

	puts msg
end

def create_or_update_attendee_sessions(attendee, ar_attendee, event_id)
  attendee_id       = ar_attendee.id
  old_sessions      = SessionsAttendee.where(attendee_id:attendee_id,flag:"web")
  old_sessions.delete_all
  selected_sessions = attendee["order_details"]
  selected_sessions.each do |s_session|
    unless s_session["product_name"].blank?
      sessions = Session.where(custom_filter_3:s_session["product_name"], event_id:event_id)
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
        @missing_sessions << s_session["product_name"]
      end
    end
  end
end

# def update_attendee_photo(ar_attendee)
#   event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id

#   if ar_attendee.photo_event_file_id != nil && ar_attendee.photo_event_file_id != ''
#     event_file = EventFile.find(ar_attendee.photo_event_file_id)
#     puts "updating photo"
#     target_path = Rails.root.join('public', 'event_data', @event_id.to_s, 'attendee_photos').to_path
#     old_photo_name = event_file.name
#     FileUtils.rm("#{target_path}/#{old_photo_name}",:force => true)
#     process_image(ar_attendee)
#   else
#     puts "creating new photo"
#     process_image(ar_attendee)
#   end

# end

# def process_image(ar_attendee)

#   photo_event_file_id = ar_attendee.photo_event_file_id
#   event_file_type_id  = EventFileType.where(name:'speaker_photo').first.id
#   event_file          = photo_event_file_id ? EventFile.find(photo_event_file_id)
#                                      : EventFile.create(event_id:@event_id,event_file_type_id:event_file_type_id)
#   filename        = "#{ar_attendee.first_name}_#{ar_attendee.last_name}_photo_#{Time.now.strftime('%Y%m%d%H%M%S')}.jpg"
#   target_path     = Rails.root.join('public', 'event_data', @event_id.to_s, 'attendee_photos').to_path
#   FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
#   event_file_path = "#{target_path.to_s.slice(target_path.to_s.index("/event_data")..-1)}/#{filename}"
#   full_path       = "#{target_path}/#{filename}"
#   image_url       = ar_attendee.custom_filter_2
#   #required for vmware links as some have strange characters
#   encoded_url = Addressable::URI.encode(image_url)

#   File.open(full_path, 'wb', 0777) {|f|
#     f.write(open(encoded_url).read)}

#   img = Magick::Image::read(full_path).first
#   img.change_geometry("300x400 #{true ? '' : '!'}") {|cols, rows, image|
#   image.resize!(cols,rows)}
#   img.write(full_path)
#   full_event_file_path =  "https://fiserv.eventkaddy.net" + event_file_path
#   event_file.update!(name:filename,path:event_file_path,mime_type:img.mime_type,size:img.filesize)
#   ar_attendee.update!(photo_event_file_id:event_file.id, photo_filename: full_event_file_path)

#   puts "photo_filename: #{full_event_file_path}"

# end

def url_exist?(url_string)
  encoded_url = Addressable::URI.encode(url_string)
  url = URI.parse(encoded_url)
  req = Net::HTTP.new(url.host, url.port)
  req.use_ssl = (url.scheme == 'https')
  path = url.path if url.path.present?
  res = req.request_head(path || '/')
  res.code != "404" && res.code != "403"# false if returns 404 - not found
rescue Errno::ENOENT
  false # false if can't find the server
end

def return_plan_tagset_array(attendee_attrs)
	['BCBS Plan/Company', attendee_attrs[:custom_filter_3], attendee_attrs[:company]]
end

def return_attendee_tag_array(attendee_attrs)
	tag_array = []
	tag_array << return_plan_tagset_array(attendee_attrs) unless attendee_attrs[:custom_filter_3].blank? || attendee_attrs[:company].blank?
	#tag_array << return_business_dicipline_tagset_array(attendee_attrs) unless attendee_attrs[:business_unit].blank?
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
attendees_url = HOST + '/attendeedata_fepfieldservice2020?proxy_key=' + MERCURY_CREDS

@event_id = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'CVENT API', row:0, status:'In Progress')
end

job.start {

  job.status  = 'Fetching data from API'
  job.write_to_file
	attendees     = JSON.parse(apiFetch(attendees_url))
  puts attendees
	tag_type_id   = TagType.where(name:'attendee').pluck(:id).first

  job.update!(total_rows:attendees.length, status:'Processing Rows')
  job.write_to_file

	attendees.each do |attendee|

    job.row    = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0

		attendee_attrs                  = return_attendee_attributes_hash(attendee)
		 attendee_tag_array              = return_attendee_tag_array(attendee_attrs)
		 attendee_attrs[:tags_safeguard] = return_tags_safeguard(attendee_tag_array)

		unless attendee["cancelled"]
			create_or_update_attendee_with_msg(attendee_attrs)
			ar_attendee = create_or_update_attendee(attendee_attrs)
      create_or_update_attendee_sessions(attendee, ar_attendee, @event_id)
			ar_attendee.update_tags attendee_tag_array, 'attendee'
		else
			remove_attendee(attendee_attrs)
		end
	end

  puts "missing sessions: #{@missing_sessions.uniq}"

  job.row = 0
  attendee_count = 0
  attendees = Attendee.where(event_id:@event_id)

  attendees.each do |ar_attendee|
    attendee_count +=1
    puts attendee_count
    puts "name: #{ar_attendee.first_name} #{ar_attendee.last_name}"

    job.update!(total_rows:attendees.length, status:'Processing Photos')
    job.write_to_file

    job.status = 'Processing Rows'
    job.row    = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0

    if ar_attendee.custom_filter_2 != '' && ar_attendee.custom_filter_2 != nil then
      if url_exist?(ar_attendee.custom_filter_2)
        update_attendee_photo(ar_attendee)
      else
        puts "ALERT: 401 ERROR"
      end
    end
  end

  job.status  = 'Cleanup'
  job.write_to_file

	Attendee.where(event_id:@event_id).each do |a|
		verifyAttendeeTags(a.tags_safeguard, tag_type_id, @event_id, a.account_code) if a.tags_safeguard!=nil
	end


}
