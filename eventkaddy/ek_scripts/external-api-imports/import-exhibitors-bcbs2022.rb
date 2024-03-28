###########################################
# Ruby script to import BCBS 2017 exhibitor
# data from SOAP proxy into EventKaddy CMS
###########################################
require 'rubygems'
require 'json'
require 'net/http'
require 'open-uri'
require 'active_record'
require_relative '../../config/environment.rb'
require_relative '../settings.rb'
require_relative '../utility-functions.rb'

def return_tagset_array_and_tags_safeguard_and_unique_subtags(exhibitor)

	unique_subtags = ''

	if exhibitor["tags"]!=nil

		exh_tagsets    = [] #store final result, all tagsets
		exhibitor_tags = ''

		if exhibitor["tags"]["category"].is_a?(Array)

			exhibitor["tags"]["category"].each do |category|

				exh_cat     = category["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')
				exh_subcats = category["sub_category"]

				if exh_subcats.is_a?(Array)

					exh_subcats.each_with_index do |subcat, i|
						unique_subtags += "#{subcat['text']}, " if subcat['text'] != category["text"]
						exh_tagsets << "#{exh_cat}:#{subcat["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')}"
					end
				else
					unique_subtags += "#{exh_subcats['text']}, " if exh_subcats["text"] != category["text"]
					exh_tagsets << "#{exh_cat}:#{exh_subcats["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')}"
				end
			end
		elsif exhibitor["tags"]["category"].is_a?(Hash)

			exh_cat     = exhibitor["tags"]["category"]["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')
			exh_subcats = exhibitor["tags"]["category"]["sub_category"]

			if exh_subcats.is_a?(Array)

				exh_subcats.each_with_index do | subcat,i|
					unique_subtags += "#{subcat["text"]}, " if subcat["text"] != exhibitor["tags"]["category"]["text"]
					exh_tagsets << "#{exh_cat}:#{subcat["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')}"
				end
			else
				unique_subtags += "#{exh_subcats["text"]}, " if exh_subcats["text"] != exhibitor["tags"]["category"]["text"]
				exh_tagsets << "#{exh_cat}:#{exh_subcats["text"].gsub(/[:,]/,' - ').gsub(/'/,'&#39;')}"
			end
		end

		exh_tagsets.each_with_index do |tagset,i|
			if (exh_tagsets[i+1]!=nil) then
				exhibitor_tags += "#{tagset},"
			else
				exhibitor_tags += tagset
			end
		end

		exhibitor_tags_result = exhibitor_tags.split(',').map { |a| a.strip }
		exhibitor_tags_result.each_with_index do |item, i|
			exhibitor_tags_result[i] = addslashes(item).split(':').map { |a| a.strip }
		end
	else
		exhibitor_tags_result = []
	end

	puts "final tagset: #{exhibitor_tags_result}"
	[exhibitor_tags_result, exhibitor_tags, unique_subtags]
end

def return_exhibitor_attributes_hash(exhibitor, event_id, exhibitor_tags, unique_subtags)

	# contact_f_name = exhibitor["contact_f_name"]
	# contact_l_name = exhibitor["contact_l_name"]
	#fax             = exhibitor["fax"]

	#custom fields
	booth_promotion_topic = exhibitor["booth_promotion_topic"]
	business_area         = exhibitor["business_area"]
	sponsorship           = exhibitor["sponsorship"]
	license_owned         = exhibitor["license_owned"]
	national_partner      = exhibitor["national_partner"]
	subcategories         = "#{unique_subtags.sub(/(.*),\s/, '\1')}"

	puts "subcats: #{subcategories}"

	#create json mapping for custom fields
	custom_fields = [{},{},{},{},{},{}]
	custom_fields[0]["title"] = "booth_promotion_topic"
	custom_fields[0]["value"] = booth_promotion_topic
	custom_fields[1]["title"] = "business_area"
	custom_fields[1]["value"] = business_area
	custom_fields[2]["title"] = "sponsorship"
	custom_fields[2]["value"] = sponsorship
	custom_fields[3]["title"] = "licensee-owned"
	custom_fields[3]["value"] = license_owned
	custom_fields[4]["title"] = "national_partner"
	custom_fields[4]["value"] = national_partner
	custom_fields[5]["title"] = "Sub-Categories"
	custom_fields[5]["value"] = subcategories

	puts "processing: #{exhibitor["company_name"]}"

# 	if (custom_fields[2]["value"]!=nil && custom_fields[2]["value"].length > 0) then
# 		is_sponsor = true
# 	else
		is_sponsor = false
# 	end

	{
	 event_id:       event_id,
   exhibitor_code: exhibitor["exhibitor_code"],
   company_name:   exhibitor["company_name"],
   description:    sanitize_for_db( exhibitor["description"] || ""),
   address_line1:  exhibitor["address_line1"],
	 address_line2:  exhibitor["address_line2"],
	 state:          exhibitor["state"],
	 city:           exhibitor["city"],
	 country:        exhibitor["country"],
	 zip:            exhibitor["zip"],
	 phone:          exhibitor["phone"],
	 email:          exhibitor["contact_email"],
	 url_web:        exhibitor["url_web"],
	 message:        exhibitor["message"],
	 contact_name:   exhibitor["contact_name"],
	 email:          exhibitor["contact_email"],
	 contact_title:  exhibitor["contact_title"],
	 custom_fields:  custom_fields.to_json,
	 tags_safeguard: exhibitor_tags,
	 #is_sponsor:     is_sponsor,
	 #sponsor_level_type_id: 6
	}
end

# def return_attendee_attributes_hash(exhibitor, event_id)

# 	attendee_type_id = AttendeeType.where(name:"Exhibitor").first.id
# 	first_name       = exhibitor["contact_f_name"].blank? ? 'Unknown' : exhibitor["contact_f_name"]
# 	last_name        = exhibitor["contact_l_name"].blank? ? 'Unknown' : exhibitor["contact_l_name"]
# 	password         = exhibitor["zip"].blank? ? 'bcbs18' : exhibitor["zip"]

# 	{event_id:            event_id,
# 	 account_code:        exhibitor["exhibitor_code"],
# 	 first_name:          first_name,
# 	 last_name:           last_name,
# 	 title:               exhibitor["contact_title"],
# 	 email:               exhibitor["contact_email"],
# 	 username:            exhibitor["contact_email"],
# 	 password:            password,
# 	 custom_filter_1:     'Exhibitor',
# 	 attendee_type_id:    attendee_type_id,
# 	 company:             exhibitor["company_name"],
# 	 business_unit:       'Exhibitors',
# 	 messaging_opt_out:   false,
# 	 app_listing_opt_out: false,
# 	 game_opt_out:        false}
# end

def update_or_create_exhibitor(exhibitor_attrs)
  exhibitor = Exhibitor.where(exhibitor_code:exhibitor_attrs[:exhibitor_code], event_id:exhibitor_attrs[:event_id]).first_or_initialize
  exhibitor.update!(exhibitor_attrs)
	exhibitor
end

def return_exhibitor_rows(exhibitor_attrs)
  Exhibitor.where(exhibitor_code:exhibitor_attrs[:exhibitor_code], event_id:exhibitor_attrs[:event_id])
end

def update_or_create_exhibitor_with_msg(exhibitor_attrs)
  rows           = return_exhibitor_rows(exhibitor_attrs)
  create_message = "--- creating exhibitor: #{exhibitor_attrs[:exhibitor_code]} #{exhibitor_attrs[:company_name]} ---\n".green
  update_message = "---- updating exhibitor: #{exhibitor_attrs[:exhibitor_code]} #{exhibitor_attrs[:company_name]} ----\n".yellow
  error_message  = "ERROR: Multiple rows for exhibitor #{exhibitor_attrs[:exhibitor_code]} #{exhibitor_attrs[:company_name]}".red

  if rows.length == 0
    msg = create_message
    Exhibitor.create(exhibitor_attrs)
  elsif rows.length == 1
    msg = update_message
    rows[0].update!(exhibitor_attrs)
  else
    msg = error_message
  end
  puts msg
end

def update_location_mapping(event_id, booth_number, location_mapping_type_id, exhibitor)

		location_mapping = LocationMapping.where(name:booth_number,event_id:event_id).first_or_initialize
		location_mapping.update!(event_id:event_id,name:booth_number,mapping_type:location_mapping_type_id)
		exhibitor.location_mapping = location_mapping
		exhibitor.save
end

# def add_prefavourites(attendee_id)
# 	PREFAVOURITES.each {|p|
# 		SessionsAttendee.where(attendee_id:attendee_id, flag:'cms_external_api', session_id:p[:session_id], session_code:p[:session_code]).first_or_create }
# end

# def update_or_create_associated_attendee(exhibitor, attendee_attrs)
# 	unless exhibitor.email.blank? || attendee_attrs[:email].blank?
# 		attendees = Attendee.where(event_id:exhibitor.event_id, email:attendee_attrs[:email])
# 		if attendees.length == 0
# 			puts "---creating attendee----"
# 			attendee = Attendee.create(attendee_attrs)
# 			puts "---creating link between attendee #{attendee.id} and #{exhibitor.company_name}----"
# 			BoothOwner.where(exhibitor_id:exhibitor.id,attendee_id:attendee.id).first_or_create
# 		elsif attendees.length == 1
# 			attendees.first.update_attributes(business_unit:attendee_attrs[:business_unit], attendee_type_id:attendee_attrs[:attendee_type_id])
# 			puts "---creating link between attendee #{attendees.first.id} and #{exhibitor.company_name}----"
# 			BoothOwner.where(exhibitor_id:exhibitor.id,attendee_id:attendees.first.id).first_or_create
# 		else
# 			puts "More than one attendee already exist with email #{exhibitor.email} for event #{exhibitor.event_id}."
# 		end
# 	end
# end

ActiveRecord::Base.establish_connection(adapter:"mysql2",host:@db_host,username:@db_user,password:@db_pass,database:@db_name)

HOST                   = 'https://bcbsproxya.eventkaddy.net'
# HOST                     = 'http://localhost:3001'
exhibitors_url         = HOST + '/exhibitordata2022?proxy_key=uniabmxcxgjzfmfxmljhtewzzhiguznyzipomdqauenzbqmnjp'
# exhibitors_url           = 'https://bcbsproxya.eventkaddy.net/exhibitordata2019?proxy_key=uniabmxcxgjzfmfxmljhtewzzhiguznyzipomdqauenzbqmnjp'
event_id                 = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:'a2z API', row:0, status:'In Progress')
end

job.start {

  job.status  = 'Fetching data from API'
  job.write_to_file

	data = apiFetch(exhibitors_url).
    gsub(//, "").
    gsub(/℠/,"(sm)").
    gsub(/®/,"(r)").
    gsub(/‐/, "-").
    gsub(/″/, '\"')

	## next time there is an error, try this:
	## .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

	# for attendee belonging to exhibitor
	# prefavourite_session_codes = [873,874,875,876,877,878,879,880,881,882,883,884,885,886,887,888]
	# PREFAVOURITES = Session.select('id, session_code').where(event_id:event_id,session_code:prefavourite_session_codes).map {|session|
	# 	{session_id:session.id, session_code:session.session_code}}

	exhibitors               = JSON.parse(data)["exhibitors"]
	api_count                = 0
	location_mapping_type_id = LocationMappingType.where(type_name:'Booth').pluck(:id).first
	tag_type_id              = TagType.where(name:'exhibitor').pluck(:id).first

  job.update!(total_rows:exhibitors.length, status:'Processing Rows')
  job.write_to_file

	exhibitors.each do |exhibitor|

    job.row    = job.row + 1
    job.write_to_file if job.row % job.rows_per_write == 0

		exhibitor_tags_result, exhibitor_tags, unique_subtags = return_tagset_array_and_tags_safeguard_and_unique_subtags(exhibitor)
		exhibitor_attrs = return_exhibitor_attributes_hash(exhibitor, event_id, exhibitor_tags, unique_subtags)
		# attendee_attrs  = return_attendee_attributes_hash(exhibitor, event_id)

    begin
      update_or_create_exhibitor_with_msg(exhibitor_attrs)
      ar_exhibitor    = update_or_create_exhibitor(exhibitor_attrs)
      # update_or_create_associated_attendee(ar_exhibitor, attendee_attrs)

      update_location_mapping(event_id, exhibitor["booth_number"], location_mapping_type_id, ar_exhibitor) if exhibitor["co_exhibitor"]==nil
      ar_exhibitor.update_tags exhibitor_tags_result, 'exhibitor'
    rescue => e
      puts e.inspect.red
      puts exhibitor_attrs[:description].inspect.red

      warning_msg =  "A database encoding error occured while updating #{exhibitor_attrs[:company_name]}, probably in the description field. This exhibitor will be skipped, but you may be able to resolve the issue on your own by retyping this exhibitor's description in plain text using an English language setting keyboard."
      job.warnings = job.warnings.blank? ? warning_msg : job.warnings + '||' + warning_msg

      job.write_to_file
      # raise "A database encoding error occured while updating #{exhibitor_attrs[:company_name]}, probably in the description field."
    end
	end

  job.status  = 'Cleanup'
  job.write_to_file


	Exhibitor.where(event_id:event_id).each do |e|
		verifyExhibitorTags(e.tags_safeguard, tag_type_id, event_id, e.company_name) if e.tags_safeguard!=nil
	end

}

