###########################################
#Ruby script to import map data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################
require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config

#other gems needed, but don't have to be requried above
 	#gem ruby-mysql
	#gem 'google-spreadsheet-ruby'
	#gem 'rubyzip2'

#from PHP land
def addslashes(str)
  str.gsub(/['"\\\x0]/,'\\\\\0')
end

#setup variables
event_id = ARGV[0] #1, 2, 3, etc
spreadsheet_file = ARGV[1] #maps-data.ods, bobs-maps.ods, etc


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']

		
# INPUT SPREADSHEET DATA	
begin

	# connect to the MySQL server
	#dbh = Mysql.real_connect(@db_host, @db_user, @db_pass, @db_name)
	dbh = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass,:database => @db_name)
	
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
			
			sql_event_maps="INSERT INTO event_maps ( id,event_id,map_event_file_id,name,filename,width,height,map_type_id,created_at,updated_at ) VALUES "# ( ?,?,?,?,?,?,?,?,?,? )"
			sql_location_mappings="INSERT INTO location_mappings ( id,event_id,map_id,name,mapping_type,x,y,created_at,updated_at ) 
			VALUES "# 	( ?,?,?,?,?,?,?,?,? )"
			sql_event_files="INSERT INTO event_files (id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at) VALUES " 
			#( ?,?,?,?,?,?,?,?,? )"
			
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
			pattern = Regexp.new('[a-zA-Z]',Regexp::IGNORECASE)
			if (colvals[0].to_s.match(pattern)) then #string detect
				location_name=colvals[0]
			else
				location_name=colvals[0].to_i.to_s
			end
			
			map_filename=colvals[1]
			x_pos=colvals[2].to_i
			y_pos=colvals[3].to_i
			map_type=colvals[4]
			
			if (map_type=='exhibitor') then
				map_type=1
				location_type=2
			elsif (map_type=='session') then
				map_type=2
				location_type=1
			else
				map_type=nil
				location_type=nil
			end
			
			puts "processing location name: #{location_name}"
			
			#-- add event_file for map --
			rows=dbh.query("SELECT id FROM `event_files` WHERE name=\"#{map_filename}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0) then
				puts "-- creating event_file for map: #{map_filename} --\n"
  					
  				#st = dbh.prepare(sql_event_files)		
  				dbh.query(sql_event_files + "('','#{event_id}','#{map_filename}','','image/jpeg','/event_data/#{event_id.to_s}/maps/#{map_filename}','2','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#(id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at)
  				#st.close
  					
  				map_event_file_id=dbh.query("SELECT id FROM `event_files` ORDER BY id DESC LIMIT 1;").first['id']			
  			else
  				map_event_file_id=rows.first['id']
  			end
						
			#-- add map --
			rows=dbh.query("SELECT id FROM `event_maps` WHERE name=\"#{map_filename}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0) then
				puts "-- creating event_map: #{map_filename} --\n"
  					
  				#st = dbh.prepare(sql_event_maps)
  				dbh.query(sql_event_maps + "('','#{event_id}','#{map_event_file_id}','#{map_filename}','#{map_filename}','','','#{map_type}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#st.close
  				#( id,event_id,map_event_file_id,name,filename,width,height,map_type_id,created_at,updated_at )
				map_id=dbh.query("SELECT id FROM `event_maps` ORDER BY id DESC LIMIT 1;").first['id']
			else
				map_id=rows.first['id']
			end
			
			puts "map_id : #{map_id}"
			
			#-- add or update location_mapping --
			rows=dbh.query("SELECT id,map_id FROM `location_mappings` WHERE name=\"#{location_name}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0) then
				puts "-- creating location_mapping: #{location_name} --\n"
  					
  				#st = dbh.prepare(sql_location_mappings)
  				dbh.query(sql_location_mappings + "('','#{event_id}','#{map_id}','#{location_name}','#{location_type}','#{x_pos}','#{y_pos}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")  				
  				#st.close
  				#( id,event_id,map_id,name,mapping_type,x,y,created_at,updated_at )
  			
  		else
				#if (rows.first['map_id'] == nil ) then #check if map_id is empty
					puts "-- updating location_mapping: #{location_name} --\n"
					dbh.query("UPDATE location_mappings SET map_id=#{map_id}, x=#{x_pos}, y=#{y_pos} WHERE id=\"#{rows.first['id']}\"")
					
				#end	
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

	
	
	
	
	

