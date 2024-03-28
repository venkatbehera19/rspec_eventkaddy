###########################################
#Ruby script to import room layout data 
#from spreadsheet (ODS) into EventKaddy CMS
###########################################

require 'roo'
require 'mysql2'
require 'date'
require 'devise'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'

#for active record usage
require 'active_record'
require '../config/environment.rb' #load the rails 3 environment

ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)


#setup variables
event_id = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #session-data.ods, bobs-sessions.ods, etc


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
			
			t = Time.now
					
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
			room_layout_title = colvals[0]
			room_layout_configuration_name = colvals[1]
			room_layout_file_name = colvals[2]
			default_room_layout = colvals[3].to_i
			location_mapping_name = colvals[4]
			

			## add room layout ##

			room_layout_title_mod = "#{location_mapping_name} - #{room_layout_title}"

			#check file extension
			m = room_layout_file_name.match(/.*(.png|.gif|.jpg|.jpeg)$/i)
			if (m!=nil) then
				file_ext = m[1]
			else
				puts "error, invalid file extension for file #{room_layout_file_name}"
				next
			end

			#retreive room layout configuration
			room_layout_configurations = RoomLayoutConfiguration.where(name:room_layout_configuration_name)

			if (room_layout_configurations.length==1) then
				room_layout_configuration_id = room_layout_configurations.first.id
			else
				puts "error, unique room layout configuration #{room_layout_configuration_name} does not exist in db"
				next
			end

			location_mappings = LocationMapping.where(name:location_mapping_name,event_id:event_id)

			location_mapping = nil
			if (location_mappings.length==1) then
				puts "found unique location mapping: #{location_mappings.first.name}"
				location_mapping = location_mappings.first
			else
				puts "error, unique location mapping does not exist for #{room_layout_title_mod}"
				next
			end

			room_layout_hash = {event_id:event_id,room_layout_configuration_id:room_layout_configuration_id,
				title:room_layout_title_mod,default:default_room_layout,location_mapping_id:location_mapping.id}

			puts "room layout hash: #{room_layout_hash}"

			room_layouts = RoomLayout.where(title:room_layout_title_mod,location_mapping_id:location_mapping.id,event_id:event_id)

			if (room_layouts.length == 0) then
				
				puts "-- creating room layout: #{room_layout_title} --\n"
				room_layout = RoomLayout.new(room_layout_hash)
				room_layout.save()
			elsif (room_layouts.length == 1)
				
				puts "---- updating room_layout: #{room_layout_title} ----\n"
				room_layout = room_layouts[0]
				room_layout.update!(room_layout_hash)
			else
				puts "--- ERROR: potential duplicate room layout: #{room_layout_title} for location mapping id: #{location_mapping.id}"
				next
			end
		
			### generate event file for room layout file
			event_file_type = EventFileType.where(name:'room_layout').first
			room_layout.event_file = EventFile.where(name:room_layout_title_mod,event_file_type_id:event_file_type.id,
				path:"/event_data/#{event_id.to_s}/room_layouts/#{location_mapping_name.gsub!(/\W/,'_')}_#{room_layout_file_name}",event_id:event_id).first_or_initialize() 

			room_layout.save()

			## link default room layout to all sessions for the location mapping
			if (room_layout.default==true) then

				room_layout.location_mapping.sessions.each do |session|
					sessions_room_layout = SessionsRoomLayout.where(session_id:session.id,room_layout_id:room_layout.id,event_id:event_id).first_or_initialize()
					sessions_room_layout.save()
				end

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


	
	
	
	
	

