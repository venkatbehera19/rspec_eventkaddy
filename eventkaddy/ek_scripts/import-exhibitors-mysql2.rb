###########################################
#Ruby script to import exhibitor data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################
require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'

require 'active_record'
require '../config/environment.rb' #load the rails 3 environment

ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

=begin
@db_host='localhost'
@db_user='ekuser'
@db_pass='wigglewort'
@db_name='eventkaddy_cms_dev_v1build'
=end

#other gems needed, but don't have to be requried above
 	#gem ruby-mysql
	#gem 'google-spreadsheet-ruby'
	#gem 'rubyzip2'



#setup variables
event_id = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

		
# INPUT SPREADSHEET DATA	
begin

	# connect to the MySQL server
	#dbh = Mysql.real_connect(@db_host, @db_user, @db_pass, @db_name)
	dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)
	#dbh.query_options.merge!(:as => :array) #return results as arrays, not hashes
	# get server version string and display it
	#puts "Server version: " + dbh.get_server_info	
	
	#open the spreadsheet  
	if ( spreadsheet_file.match(/.xls/) || spreadsheet_file.match(/.xlsx/) )
		oo = Roo::Excel.new(spreadsheet_file)
		
	elsif ( spreadsheet_file.match(/.ods/) )
		oo = Roo::Openoffice.new(spreadsheet_file)	
	
	else
		puts "Spreadsheet format not supported"
		exit
	end
	
	#process all the sheets
	oo.sheets.each do |sheet|
	
		puts "--------- Processing sheet: #{sheet} ------------\n"
		oo.default_sheet = sheet
		
		#get field names from first row
		fields = []
		fieldcount=0
		1.upto(1) do |row|
			colLetter.each do |col|
				
				if (oo.cell(row,col)!=nil) then
					fields[fieldcount]=oo.cell(row,col)
					#puts fields[fieldcount] + "\n"
					fieldcount+=1
				end
				
			end #col
		end #row 
	
		puts fields.inspect + "\n"
		
		#get records on sheet
		colvals=[]
		2.upto(oo.last_row) do |row|
			
			t = Time.now
			
			sql_exhibitors = "INSERT INTO exhibitors ( id, location_mapping_id,event_id,user_id,logo_event_file_id,sponsor_level_type_id,company_name,description,
			logo,address_line1,address_line2,city,zip,state,country,email,phone,fax,url_web,url_twitter,url_facebook,url_linkedin,url_rss,
			message,is_sponsor,created_at,updated_at ) VALUES "# ( ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? )"
			sql_enhanced_listings="INSERT INTO enhanced_listings ( id,exhibitor_id,event_file_id,product_name,product_image,product_description,
			product_link,created_at,updated_at) VALUES " #( ?,?,?,?,?,?,?,?,? )"
			sql_location_mappings="INSERT INTO location_mappings ( id,event_id,map_id,name,mapping_type,x,y,created_at,updated_at ) 
			VALUES "# 	( ?,?,?,?,?,?,?,?,? )"
			sql_event_files="INSERT INTO event_files (id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at) VALUES "# ( ?,?,?,?,?,?,?,?,? )"
			sql_tags = "INSERT INTO tags (id,name,level,leaf,parent_id,event_id,tag_type_id,created_at,updated_at ) VALUES "
			sql_tags_exhibitors = "INSERT INTO tags_exhibitors (id,tag_id,exhibitor_id,created_at,updated_at) VALUES "
			
			#collect all the column values for the row
			0.upto(fieldcount-1) do |colnum|
				
				#collect value, if any
				if (oo.cell(row,colLetter[colnum])==nil) then
					colvals[colnum]=''
				else
					colvals[colnum] =oo.cell(row,colLetter[colnum])
				end
			
			end #col
			
			#column mappings
			company_name=addslashes(colvals[0])
			#booth_name=addslashes(colvals[1].to_i.to_s)
			logo=colvals[2]
			description=addslashes(colvals[3])
			address_line1=addslashes(colvals[4].to_s)
			if (is_number(colvals[5])) then
				address_line2 = addslashes(colvals[5].to_i.to_s)
			else
				address_line2 = addslashes(colvals[5])			
			end
			city=colvals[6]
			state=colvals[7]
			if (is_number(colvals[8])) then
				zip = colvals[8].to_i.to_s
			else
				zip = colvals[8]			
			end
			country=colvals[9]
			email=colvals[10]
			phone=colvals[11]
			fax=colvals[12]
			message=addslashes(colvals[13])
			url_facebook=colvals[14]
			url_linkedin=colvals[15]
			url_rss=colvals[16]
			url_twitter=colvals[17]
			url_web=colvals[18]
			is_sponsor=colvals[19]
			product_name=addslashes(colvals[20])
			product_description=addslashes(colvals[21])
			product_image=colvals[22]
			product_link=colvals[23]
			sponsor_level_id=colvals[24]
						

			
			#exhibitor_tags = addslashes(colvals[23]).split(',').map { |a| a.strip }
			exhibitor_tags = addslashes(colvals[25]).split('##').map { |a| a.strip }
			exhibitor_tags.each_with_index do |item,i|
				exhibitor_tags[i] = addslashes(item).split(':').map { |a| a.strip }
			end
			
			#allow booth_name to be either string or int
			pattern = Regexp.new('[a-zA-Z]',Regexp::IGNORECASE)
			if (colvals[1].to_s.match(pattern)) then #string detect
				booth_name=colvals[1]
			else
				booth_name=colvals[1].to_i.to_s
			end

			user_email=colvals[26]

			users=User.where(email:user_email)
			role = Role.where(name:"Exhibitor").first

			if (users.length==0 && user_email!="") then
 				user = User.new
  				user.email = user_email
  				user.password = 'ekchangeme'
  				user.save()
  				puts "user id: #{user.id}"

  				user_role = UsersRole.new()
  				user_role.role_id=role.id
  				user_role.user_id=user.id
  				user_role.save()
  			elsif (user_email=="") then
  				##test if this works
  				puts "cannot create user with blank email"
  				user=User.new()
  				user.id=0
  			else
  				puts "user already exists with email address: #{user_email}"
  				user = users.first
  			end					
			

			#add location_mapping
			rows=dbh.query("SELECT id FROM `location_mappings` WHERE name=\"#{booth_name}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0 ) then
				puts "-- creating location_mapping: #{booth_name} --\n"
  					
  				#st = dbh.prepare(sql_location_mappings)
  				dbh.query(sql_location_mappings + "('','#{event_id}','','#{booth_name}','2','','','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#st.close
  				puts "created location_mapping"
			end
			
			#add exhibitor
			location_mapping_id=dbh.query("SELECT id FROM `location_mappings` WHERE name=\"#{booth_name}\" AND event_id=\"#{event_id}\"")
			rows=dbh.query("SELECT id,is_sponsor FROM `exhibitors` WHERE company_name=\"#{company_name}\" AND event_id=\"#{event_id}\";").to_a
			puts rows
			if (rows.count == 0) then
				puts "-- creating new exhibitor: #{company_name} --\n"
  				
  				#add exhibitor logo
  				logo_event_file_id=''
  				if (logo!='') then
  					#st = dbh.prepare(sql_event_files)
  					dbh.query(sql_event_files + "('','#{event_id}','#{logo}','','image/jpeg',
  					'/event_data/#{event_id.to_s}/exhibitor_logos/#{logo}','4',
  					'#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  					#(id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at)
  					
  					logo_event_file_id=dbh.query("SELECT id FROM `event_files` ORDER BY id DESC LIMIT 1;").first['id']
  				end
  				
  				#st = dbh.prepare(sql_exhibitors)
  				dbh.query(sql_exhibitors + "('','#{location_mapping_id.first['id']}','#{event_id}','#{user.id}','#{logo_event_file_id}','#{sponsor_level_id}','#{company_name}','#{description}','#{logo}',
  				'#{address_line1}','#{address_line2}','#{city}','#{zip}','#{state}','#{country}','#{email}','#{phone}','#{fax}','#{url_web}','#{url_twitter}','#{url_facebook}','#{url_linkedin}','#{url_rss}',
  				'#{message}','#{is_sponsor}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#( id, location_mapping_id,event_id,user_id,logo_event_file_id,company_name,description,
			#logo,address_line1,address_line2,zip,state,country,phone,fax,url_web,url_twitter,url_facebook,url_linkedin,url_rss,
			#message,is_sponsor,created_at,updated_at ) 
  				#st.close
			elsif (rows.count == 1 && rows[0]['is_sponsor'] == 1) #update the existing sponsor's info
				puts "-- updating exhibitor (sponsor): #{company_name} --\n"
	
				dbh.query("UPDATE exhibitors SET location_mapping_id='#{location_mapping_id.first['id']}',logo_event_file_id='#{logo_event_file_id}',
				sponsor_level_type_id='#{sponsor_level_id}',company_name='#{company_name}',description='#{description}',logo='#{logo}',message='#{message}', 
				address_line1='#{address_line1}',address_line2='#{address_line2}',city='#{city}',zip='#{zip}',state='#{state}',country='#{country}',email='#{email}',phone='#{phone}',
				fax='#{fax}',url_web='#{url_web}',url_twitter='#{url_twitter}',url_facebook='#{url_facebook}',url_linkedin='#{url_linkedin}',url_rss='#{url_rss}',
				updated_at='#{t.strftime("%Y-%m-%d %H:%M:%S")}' WHERE id='#{rows[0]['id']}' ")
			end

			#add enhanced listing
			exhibitor_id=dbh.query("SELECT id FROM `exhibitors` WHERE company_name=\"#{company_name}\" AND event_id=\"#{event_id}\"")
			
			rows=dbh.query("SELECT id FROM `enhanced_listings` WHERE product_name=\"#{product_name}\" AND exhibitor_id=\"#{exhibitor_id}\";")	
			if (rows.count == 0 and product_name!="") then
				puts "\t-- creating new enhanced listing for: #{product_name} --\n"
  								
  				#st = dbh.prepare(sql_enhanced_listings)
  				dbh.query(sql_enhanced_listings + "('','#{exhibitor_id.first['id']}','','#{product_name}','#{product_image}','#{product_description}','#{product_link}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#( id,exhibitor_id,event_file_id,product_name,product_image,product_description,
				#product_link,created_at,updated_at)
  				#st.close
			end


			### add exhibitor tags ###

			rows=dbh.query("SELECT id FROM `tag_types` WHERE name=\"exhibitor\";")
			tag_type_id=rows.first['id']

			addExhibitorTags(dbh,event_id,exhibitor_tags,tag_type_id,company_name)
			
		end #row 
	
	end #sheet
	
	
rescue Mysql2::Error => e
	puts "Error code: #{e.errno}"
	puts "Error message: #{e.error}"
	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
	# disconnect from server
	dbh.close if dbh
end

	
	
	
	
	

