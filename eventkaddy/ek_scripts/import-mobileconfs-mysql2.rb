###########################################
#Ruby script to import mobileconf data from
#spreadsheet (.ods format) into EventKaddy CMS
##########################################
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
			
			sql_home_button_groups="INSERT INTO home_button_groups ( id,event_id,event_file_id,name,icon_button,position,created_at,updated_at ) 
			VALUES " # ( ?,?,?,?,?,?,?,? )"
			sql_home_button_entries="INSERT INTO home_button_entries ( id,group_id,event_file_id,render_url,name,icon_entry,content,position,created_at,updated_at ) 
			VALUES " # 	( ?,?,?,?,?,?,?,?,?,? )"
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
					
			hs_button_name=colvals[0]
			hs_icon_filename=colvals[1]
			hs_position=colvals[2]
			ss_button_name=colvals[3]
			ss_icon_filename=colvals[4]
			ss_render_url=colvals[5]
			ss_content=colvals[6]
			ss_position=colvals[7]
			
			#add home screen icon file
			rows=dbh.query("SELECT id FROM `event_files` WHERE name=\"#{hs_icon_filename}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0) then
				puts "-- creating event_file for home button group: #{hs_button_name} --\n"
  					
  				#st = dbh.prepare(sql_event_files)		
  				dbh.query(sql_event_files + "('','#{event_id}','#{hs_icon_filename}','','image/png',
  				'/event_data/#{event_id.to_s}/home_button_group_images/#{hs_icon_filename}','8'
  				,'#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#(id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at)
  				#st.close
  					
  				hs_event_file_id=dbh.query("SELECT id FROM `event_files` ORDER BY id DESC LIMIT 1;").first['id']			
  			else
  				hs_event_file_id=rows.first['id']
  			end
  			
  			#add home button group
			rows=dbh.query("SELECT id FROM `home_button_groups` WHERE name=\"#{hs_button_name}\" AND event_id=\"#{event_id}\";")	
			if (rows.count == 0) then
				puts "-- creating home button group: #{hs_button_name} --\n"
  					
  				#st = dbh.prepare(sql_home_button_groups)
  				dbh.query(sql_home_button_groups + "('','#{event_id}','#{hs_event_file_id}','#{hs_button_name}','#{hs_icon_filename}','#{hs_position}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
  				#st.close
  				#( id,event_id,event_file_id,name,icon_button,position,created_at,updated_at )
			end
  			
  			
  			
  			#add subscreen data if defined
			if (ss_button_name!='' ) then
				
				#add subscreen icon file
				rows=dbh.query("SELECT id FROM `event_files` WHERE name=\"#{ss_icon_filename}\" AND event_id=\"#{event_id}\";")	
				if (rows.count == 0) then
					puts "\t-- creating event_file for subscreen button: #{ss_button_name} --\n"
	  					
	  				#st = dbh.prepare(sql_event_files)		
	  				dbh.query(sql_event_files + "('','#{event_id}','#{ss_icon_filename}','','image/png',
	  				'/event_data/#{event_id.to_s}/home_button_entry_images/#{ss_icon_filename}','9',
	  				'#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
	  				#(id,event_id,name,size,mime_type,path,event_file_type_id,created_at,updated_at)
	  				#st.close
	  					
	  				ss_event_file_id=dbh.query("SELECT id FROM `event_files` WHERE name=\"#{ss_icon_filename}\" 
	  				AND event_id=\"#{event_id}\";").first['id']			
	  			else
	  				ss_event_file_id=rows.first['id']
	  			end
				
				#add subscreen
				hs_button_id=dbh.query("SELECT id FROM `home_button_groups` WHERE name=\"#{hs_button_name}\" 
				AND event_id=\"#{event_id}\";").first['id']
				rows=dbh.query("SELECT home_button_entries.id FROM `home_button_entries` LEFT JOIN home_button_groups ON ( home_button_entries.group_id=home_button_groups.id ) WHERE home_button_entries.name=\"#{ss_button_name}\" AND home_button_groups.event_id=\"#{event_id}\";")	
				if (rows.count == 0) then
					puts "\t-- creating home button entry: #{ss_button_name} --\n"
	  					
	  				#st = dbh.prepare(sql_home_button_entries)
	  				dbh.query(sql_home_button_entries + "('','#{hs_button_id}','#{ss_event_file_id}','#{ss_render_url}','#{ss_button_name}','#{ss_icon_filename}','#{ss_content}','#{ss_position}','#{t.strftime("%Y-%m-%d %H:%M:%S")}','#{t.strftime("%Y-%m-%d %H:%M:%S")}')")
	  				#st.close
	  				#( id,group_id,event_file_id,render_url,name,icon_entry,content,position,created_at,updated_at )
				end
  			
  			end #if (ss_icon_filename!=''
  			
						
						
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

	
	
	
	
	

