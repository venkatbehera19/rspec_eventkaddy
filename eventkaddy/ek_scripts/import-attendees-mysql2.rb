###########################################
#Ruby script to import attendee data from
#spreadsheet into EventKaddy CMS
###########################################

require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'


#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../config/environment.rb'  


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#setup variables
event_id = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #maps-data.ods, bobs-maps.xls, etc


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

		
# INPUT SPREADSHEET DATA	
begin

	# connect to the MySQL server
	dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)
	
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
			
# 			t = Time.now
# 			
# 			sql_attendees="INSERT INTO attendees ( id,event_id,first_name,last_name,honor_prefix,honor_suffix,title,company,biography,business_unit,business_phone,mobile_phone,email,photo_filename,photo_event_file_id,created_at,updated_at,account_code ) VALUES "
# 			sql_event_files="INSERT INTO event_files (id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at) VALUES " 
			
			
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
			first_name = colvals[0]
			last_name = colvals[1]
			honor_prefix = colvals[2]
			honor_suffix = colvals[3]
			title = colvals[4]		
			company = colvals[5]
			biography = colvals[6]
			business_unit = colvals[7]
			
			if (is_number(colvals[8])) then
				business_phone = colvals[8].to_i.to_s
			else
				business_phone = colvals[8]			
			end
			
			if (is_number(colvals[9])) then
				mobile_phone = colvals[9].to_i.to_s
			else
				mobile_phone = colvals[9]			
			end

			email = colvals[10]
			registration_id = colvals[13].to_i.to_s
			#password = colvals[12]
			username = colvals[11]
			password = colvals[12]
						

			#split out the registered sessions into an array
			registered_sessions = colvals[13].split(',').map { |a| a.strip }
					
			attendee_attrs = {event_id:event_id,first_name:first_name,last_name:last_name,honor_prefix:honor_prefix,
				honor_suffix:honor_suffix,title:title,company:company,biography:biography,business_unit:business_unit,
				business_phone:business_phone,mobile_phone:mobile_phone,email:email,username:username,password:password,account_code:registration_id}

			#-- add/update attendee --
			
			attendees = Attendee.where(account_code:registration_id,event_id:event_id)
			if (attendees.length==0) then
				puts "creating attendee #{first_name} #{last_name}"
				attendee = Attendee.new(attendee_attrs)
			elsif (attendees.length==1) then
				puts "updating attendee #{first_name} #{last_name}"
				attendee = attendees[0]
				attendee.update!(attendee_attrs)
			end

			attendee.save()
			
			#remove existing sessionsattendees
			SessionsAttendee.where(attendee_id:attendee.id).destroy_all

			#-- add association for registered sessions --

			registered_sessions.each do |session_code|

				session = Session.where(session_code:session_code).first
				if (session==nil); next end

				puts "creating/updating association between #{session.session_code} and #{attendee.first_name} #{attendee.last_name}"
				session_attendee = SessionsAttendee.where(session_code:session.session_code,attendee_id:attendee.id).first_or_initialize()
				session_attendee.update!({session_id:session.id,attendee_id:attendee.id,session_code:session.session_code,flag:'cms_external_api'})
				session_attendee.save()

			end									
						
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

	
	
	
	
	

