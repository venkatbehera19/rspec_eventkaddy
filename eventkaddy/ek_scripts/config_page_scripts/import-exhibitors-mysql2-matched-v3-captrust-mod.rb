###########################################
#Ruby script to import exhibitor data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",
	:host     => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

def remove_exhibitor_tags(event_id, tag_type_id)

  Tag.where(event_id:event_id,tag_type_id:tag_type_id).each do |tag|
    tag.destroy unless tag.exhibitors.length === 0
  end
end

def add_files_to_exhibitor_description(exhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)

	description = ''
  event = Event.find(event_id)
	exhibitor_files_url.each_with_index {|url, i|
		description += %[<a href="javascript:window.open('#{event.cms_url}/event_data/#{event_id}/exhibitor_files/#{url}', '_system', 'location=yes');"><img width="40px" src="./imgs/pdf.png">#{exhibitor_files_title[i]}</a> <br><br>]}

	exhibitor.update!(description:description)

end

##modify for exhibitors
# def makeJson(currentexhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)
# 	hash = currentexhibitor.custom_fields
# 	if !(hash.blank?)
# 		hash = JSON.parse(hash)
# 	else
# 		hash = JSON.parse("[]")
# 	end

# 	exhibitor_files_url.each_with_index do |url, i|
# 		#url.gsub!(/\s/,'_')
# 		puts "--- url: #{url} ---"
# 		hash.reject! {|x| x["title"]==="#{exhibitor_files_title[i]}"}
# 		hash << {"title"=>"#{exhibitor_files_title[i]}",
# 		"url"=>"/event_data/#{event_id}/exhibitor_files/#{url}",
# 		"type"=>"#{exhibitor_files_type[i]}"}

# 		#make exhibitor_file
# 		event_files = EventFile.where(event_id:event_id,path:"/event_data/#{event_id}/exhibitor_files/#{url}")
# 		if event_files.length===1
# 			puts "--- updating exhibitor_file ---"
# 			event_file   = event_files.first

# 			exhibitor_files = ExhibitorFile.where(event_file_id:event_file.id)

# 			## fix for script not creating more than one exhibitor file per exhibitor)
# 			if exhibitor_files.length===1
# 				exhibitor_file = exhibitor_files.first
# 				exhibitor_file.title                   = exhibitor_files_title[i]
# 				exhibitor_file.exhibitor_file_type_id  = ExhibitorFileType.where(name:"exhibitor_document").first.id
# 				exhibitor_file.description             = "Exhibitor File"
# 				exhibitor_file.event_id                = event_id
# 				exhibitor_file.exhibitor_id            = currentexhibitor.id
# 				exhibitor_file.save()
# 			elsif exhibitor_files.length===0
# 				exhibitor_file = ExhibitorFile.new()
# 				exhibitor_file.title                   = exhibitor_files_title[i]
# 				exhibitor_file.exhibitor_file_type_id  = ExhibitorFileType.where(name:"exhibitor_document").first.id
# 				exhibitor_file.description             = "Exhibitor File"
# 				exhibitor_file.event_id                = event_id
# 				exhibitor_file.exhibitor_id            = currentexhibitor.id
# 				exhibitor_file.event_file_id           = event_file.id
# 				exhibitor_file.save()
# 			else
# 				puts "ERROR: More than one exhibitor file belongs to event_file"
# 			end

# 			event_file.update!(mime_type:exhibitor_files_type[i])
# 			# exhibitor_file.update!(title:exhibitor_files_title[i])
# 		elsif event_files.length===0
# 			puts "--- creating exhibitor file and placeholder event file"

# 			if ExhibitorFile.where(exhibitor_id:currentexhibitor.id,title:exhibitor_files_title[i]).length===0
# 				exhibitor_file = ExhibitorFile.new()
# 				exhibitor_file.title                   = exhibitor_files_title[i]
# 				exhibitor_file.exhibitor_file_type_id  = ExhibitorFileType.where(name:"exhibitor_document").first.id
# 				exhibitor_file.description             = "Exhibitor File"
# 				exhibitor_file.event_id                = event_id
# 				exhibitor_file.exhibitor_id            = currentexhibitor.id
# 				exhibitor_file.save()
# 			else
# 				exhibitor_file = ExhibitorFile.where(exhibitor_id:currentexhibitor.id,title:exhibitor_files_title[i]).first
# 			end


# 			event_file                           = EventFile.new()
# 			event_file.name                      = url
# 			event_file.event_file_type_id        = EventFileType.where(name:"exhibitor_file").first.id
# 			event_file.path                      = "/event_data/#{event_id}/exhibitor_files/#{url}"
# 			event_file.mime_type                 = exhibitor_files_type[i]
# 			event_file.event_id                  = event_id
# 			event_file.save()

# 			exhibitor_file.update!(event_file_id:event_file.id)

# 		else
# 			puts "---ERROR duplicate event files, #{event_files.inspect} ---"
# 		end

# 	end
# 	puts "--- adding #{hash} to exhibitor_file_urls ---"
# 	currentexhibitor.update!(:custom_fields => hash.to_json)

# end

def generate_columns_error_log(nonexistant_columns, event_id)
	@error_log += "The following columns are incorrectly named:\n\n"

	nonexistant_columns.each {|c| @error_log += "\t" + c + "\n"}

	new_filename = "error_log.txt"
	filepath     = Rails.root.join('public','event_data', event_id.to_s,'error_logs',new_filename)
	dirname      = File.dirname(filepath)

	@error_log   = "Refresh Error Report\n\nNumber of Errors: #{@error_count}\n\n\n\n\n" + @error_log


	FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

	File.open(filepath, "w", 0777) { |file| file.puts @error_log }
end

#setup variables
event_id         = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #exhibitor-data.ods, bobs-exhibtors.ods, etc

@error_count     = 0
@error_log       = ''

colLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

array_of_tag_arrays_and_company_names = []

# INPUT SPREADSHEET DATA

#open the spreadsheet
if (spreadsheet_file.match(/.xlsx/))
	oo = Roo::Excelx.new(spreadsheet_file)
elsif ( spreadsheet_file.match(/.xls/) )
	oo = Roo::Excel.new(spreadsheet_file)
elsif ( spreadsheet_file.match(/.ods/) )
	oo = Roo::Openoffice.new(spreadsheet_file)
else
	puts "Spreadsheet format not supported"
	exit
end

## Have to remove existing listings because there isn't a unique identifier
# EnhancedListing.where(event_id:event_id).delete

#process all the sheets
oo.sheets.each do |sheet|

	puts "--------- Processing sheet: #{sheet} ------------\n"
	oo.default_sheet = sheet

	#get field names from first row
	fields     = []
	fieldcount = 0
	1.upto(1) do |row|
		colLetter.each do |col|

			if (oo.cell(row,col)!=nil) then
				fields[fieldcount] = oo.cell(row,col)
				#puts fields[fieldcount] + "\n"
				fieldcount += 1
			end

		end #col
	end #row

	puts fields.inspect + "\n"

		nonexistant_columns = []

		fields.each_with_index do |f, i|
			case f.downcase
			when 'company name'
				@company_name_col              = i
			when 'booth name'
				@booth_name_col                = i
			when 'logo'
				@logo_col                      = i
			when 'description'
				@description_col               = i
			when 'address 1'
				@address1_col                  = i
			when 'address 2'
				@address2_col                  = i
			when 'city'
				@city_col                      = i
			when 'state'
				@state_col                     = i
			when 'zip'
				@zip_col                       = i
			when 'country'
				@country_col                   = i
			when 'phone'
				@phone_col                     = i
			when 'fax'
				@fax_col                       = i
			when 'toll free'
				@toll_free_col                 = i
			when 'contact name'
				@contact_name_col              = i
			when 'email'
				@email_col                     = i
			when 'contact title'
				@contact_title_col             = i
			when 'message'
				@message_col                   = i
			when 'url facebook'
				@url_facebook_col              = i
			when 'url linkedin'
				@url_linkedin_col              = i
			when 'url rss'
				@url_rss_col                   = i
			when 'url twitter'
				@url_twitter_col               = i
			when 'url web'
				@url_web_col                   = i
			when 'is sponsor?'
				@is_sponsor_col                = i
			when 'sponsor level id'
				@sponsor_level_id_col          = i
			when 'exhibitor tags'
				@exhibitor_tags_col            = i
			when 'exhibitor file titles'
				@exhibitor_file_titles_col     = i
			when 'exhibitor file filenames'
				@exhibitor_file_filenames_col  = i
			when 'exhibitor file extensions'
				@exhibitor_file_extensions_col = i
			else
				nonexistant_columns << f
				@error_count += 1
			end

		end

		if nonexistant_columns.length > 0
			generate_columns_error_log(nonexistant_columns, event_id)
			raise "The following columns are incorrectly named: #{nonexistant_columns.inspect}".red
		end

	#get records on sheet
	colvals = []
	2.upto(oo.last_row) do |row|

		t = Time.now

		#collect all the column values for the row
		0.upto(fieldcount-1) do |colnum|

			#collect value, if any
			if (oo.cell(row,colLetter[colnum])==nil) then
				colvals[colnum] = ''
			else
				colvals[colnum] = oo.cell(row,colLetter[colnum])
			end

		end #col


		@company_name_col ? company_name = colvals[@company_name_col] : company_name = nil

		#allow booth_name to be either string or int
		pattern = Regexp.new('[a-zA-Z]',Regexp::IGNORECASE)
		if @booth_name_col
			if (colvals[1].to_s.match(pattern)) then #string detect
				booth_name = colvals[@booth_name_col]
			else
				booth_name = colvals[@booth_name_col].to_i.to_s
			end
		else
			booth_name = nil
		end

		@logo_col        ? logo          = colvals[@logo_col]          : logo          = nil
		@description_col ? description   = colvals[@description_col]   : description   = nil
		@address1_col    ? address_line1 = colvals[@address1_col].to_s : address_line1 = nil

		if @address2_col
			if (is_number(colvals[@address2_col])) then
				address_line2 = colvals[@address2_col].to_i.to_s
			else
				address_line2 = colvals[@address2_col]
			end
		else
			address_line2 = nil
		end

		@city_col  ? city  = colvals[@city_col]  : city  = nil
		@state_col ? state = colvals[@state_col] : state = nil

		if @zip_col
			if (is_number(colvals[8])) then
				zip = colvals[8].to_i.to_s
			else
				zip = colvals[8]
			end
		else
			zip = nil
		end

		@country_col ? country = colvals[9] : country = nil

		if @phone_col
			if (is_number(colvals[10]))
				phone = colvals[10].to_i.to_s
			else
				phone = colvals[10]
			end
		else
			phone = nil
		end

		if @fax_col
			if (is_number(colvals[11])) then
				fax = colvals[11].to_i.to_s
			else
				fax = colvals[11]
			end
		else
			fax = nil
		end

		@toll_free_col        ? toll_free        = colvals[@toll_free_col]        : toll_free        = nil
		@contact_name_col     ? contact_name     = colvals[@contact_name_col]     : contact_name     = nil
		@email_col            ? email            = colvals[@email_col]            : email            = nil
		@contact_title_col    ? contact_title    = colvals[@contact_title_col]    : contact_title    = nil
		@message_col          ? message          = colvals[@message_col]          : message          = nil
		@url_facebook_col     ? url_facebook     = colvals[@url_facebook_col]     : url_facebook     = nil
		@url_linkedin_col     ? url_linkedin     = colvals[@url_linkedin_col]     : url_linkedin     = nil
		@url_rss_col          ? url_rss          = colvals[@url_rss_col]          : url_rss          = nil
		@url_twitter_col      ? url_twitter      = colvals[@url_twitter_col]      : url_twitter      = nil
		@url_web_col          ? url_web          = colvals[@url_web_col]          : url_web          = nil
		@is_sponsor_col       ? is_sponsor       = colvals[@is_sponsor_col]       : is_sponsor       = nil
		@sponsor_level_id_col ? sponsor_level_id = colvals[@sponsor_level_id_col] : sponsor_level_id = nil

		if @exhibitor_tags_col
			exhibitor_tags = colvals[24].split('^^').map { |a| a.strip }
			exhibitor_tags.each_with_index do |item,i|
				exhibitor_tags[i] = item.split('||').map { |a| a.strip }
			end
		else
			exhibitor_tags = []
		end

		####### JSON STUFF ########
		if @exhibitor_file_filenames_col && @exhibitor_file_titles_col && @exhibitor_file_extensions_col
			if colvals[26] != nil then
				##this is actually just the filename now, we build the url.
				exhibitor_files_url = colvals[26].split(',').map { |a| a.strip }
				if colvals[25] != nil then
					exhibitor_files_title = colvals[25].split(',').map { |a| a.strip }
				end
				if colvals[27] != nil then
					exhibitor_files_type = colvals[27].split(',').map { |a| a.strip }
				end
			else
				exhibitor_files_url   = ''
				exhibitor_files_title = ''
				exhibitor_files_type  = ''
			end
		else
			exhibitor_files_url   = ''
			exhibitor_files_title = ''
			exhibitor_files_type  = ''
		end

		puts "company_name: #{company_name}\n"

		exhibitor_attrs = {event_id:event_id,company_name:company_name,logo:logo,description:description,address_line1:address_line1,address_line2:address_line2,city:city,state:state,zip:zip,country:country,contact_name:contact_name,email:email,phone:phone,fax:fax,message:message,url_facebook:url_facebook,url_linkedin:url_linkedin,url_rss:url_rss,url_twitter:url_twitter,url_web:url_web,toll_free:toll_free,contact_title:contact_title,is_sponsor:is_sponsor,sponsor_level_type_id:sponsor_level_id }

		location_mapping_attrs = {event_id:event_id,name:booth_name,mapping_type:LocationMappingType.where(type_name:'Booth').first.id }

		## not in use, but would be for Exhibitor Portal stuff

		# users = User.where(email:user_email)
		# role  = Role.where(name:"Exhibitor").first

		# if (users.length===0 && user_email!="") then
		# 	user          = User.new
		# 	user.email    = user_email
		# 	user.password = 'ekchangeme'
	# 			user.save()
	# 			puts "user id: #{user.id}"

		# 	user_role         = UsersRole.new()
		# 	user_role.role_id = role.id
		# 	user_role.user_id = user.id
	# 			user_role.save()

	# 	elsif (user_email==="") then
	# 			puts "cannot create user with blank email"
		# 	user    = User.new()
		# 	user.id = 0
	# 	else
	# 			puts "user already exists with email address: #{user_email}"
	# 			user = users.first
	# 	end

		#add/update location mapping

		location_mappings = LocationMapping.where(name:booth_name,event_id:event_id)
		if (location_mappings.length===0) then
			location_mapping = LocationMapping.new(location_mapping_attrs)
		else
			location_mapping = location_mappings[0]
			location_mapping.update!(location_mapping_attrs)
		end
		location_mapping.save()

		#-- add/update exhibitor --

		exhibitors = Exhibitor.where(company_name:company_name,event_id:event_id)
		if (exhibitors.length===0) then
			exhibitor = Exhibitor.new(exhibitor_attrs)
			exhibitor.save()
			if exhibitor_files_url!=""
				# makeJson(exhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)
				add_files_to_exhibitor_description(exhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)
			end
		elsif (exhibitors.length>0) then
			exhibitor = exhibitors[0]
			exhibitor.update!(exhibitor_attrs)
			if exhibitor_files_url!=""
				# makeJson(exhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)
				add_files_to_exhibitor_description(exhibitor,exhibitor_files_url,exhibitor_files_title,exhibitor_files_type,event_id)
			end
		end

		exhibitor.location_mapping = location_mapping

		## This would create a logo in our event files (placeholder?) but the data they send us is a url to their own hosted logo.

		# if logo!="" && exhibitor.logo_event_file_id.blank?
		# 	logo_event_file = EventFile.new
		# 	logo_event_file.update!(event_id:event_id,name:logo,mime_type:"image/jpeg",path:"/event_data/#{event_id.to_s}/exhibitor_logos/#{logo}",event_file_type_id:EventFileType.where(name:"exhibitor_logo").first.id)
		# elsif logo!=""
		# 	exhibitor.logo_event_file.update!(event_id:event_id,name:logo,mime_type:"image/jpeg",path:"/event_data/#{event_id.to_s}/exhibitor_logos/#{logo}",event_file_type_id:EventFileType.where(name:"exhibitor_logo").first.id)
		# end

		exhibitor.save()

		# tag_type_id = TagType.where(name:"exhibitor").first.id
		# addExhibitorTagsV2(event_id,exhibitor_tags,tag_type_id,company_name)
		array_of_tag_arrays_and_company_names << {:company_name => company_name, :exhibitor_tags => exhibitor_tags}

	end #row
end #sheet

## remove old tags and add new tags

tag_type_id = TagType.where(name:'exhibitor').first.id

remove_exhibitor_tags(event_id, tag_type_id)
add_tags_for_all_exhibitors(array_of_tag_arrays_and_company_names, event_id, tag_type_id)

##Tagset Verification

exhibitors  = Exhibitor.where(event_id:event_id)


exhibitors.each do |exhibitor|
	if (exhibitor.tags_safeguard!=nil) then
		verifyExhibitorTags(exhibitor.tags_safeguard,tag_type_id,event_id,exhibitor.company_name)
	end
end

