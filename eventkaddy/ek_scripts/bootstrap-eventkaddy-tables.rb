##################################################
# Script to import default values for a selction
# of EventKaddy CMS tables
#
##################################################

#require 'rubygems'
require 'roo'
require 'mysql2'
require 'date'

require_relative './settings.rb' #config
require_relative './utility-functions.rb'

#setup variables
spreadsheet_file = ARGV[0] #session-data.ods, bobs-sessions.ods, etc

colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL',
'AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']
	
# ------- INPUT DEFAULT TABLE VALUES FROM SPREADSHEET --------	
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
	
	#oo = Openoffice.new("./ek_defaults_spreadsheet.ods")
	
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
		
			sql= 'INSERT INTO `' + oo.default_sheet + '` VALUES ('
			
			#check if row already in db
			colvals[0] = addslashes(oo.cell(row,colLetter[0]).to_s)
			rows=dbh.query("SELECT id FROM `#{oo.default_sheet}` WHERE id=\"#{colvals[0]}\"")
			if ( rows.count != 0 ) then
				puts "id #{colvals[0].to_i} already exists in table #{oo.default_sheet}"
				next
			else
				sql+='\'' + '' + '\',' 
			end
			
				
			1.upto(fieldcount + 1) do |colnum| #automatically add `created_at` and `updated_at` fields
				
				#acquire column value for this row
				if (oo.cell(row,colLetter[colnum])==nil) then
					colvals[colnum]=''
				else
					colvals[colnum] = addslashes(oo.cell(row,colLetter[colnum]).to_s)
				end
								
		
				if (colnum < fieldcount) then
					sql+='\'' + colvals[colnum] + '\',' 
					
				elsif (colnum==fieldcount) then # `created_at`
					t = Time.now
					sql+='\'' + t.strftime("%Y-%m-%d %H:%M:%S") + '\','
					 
				elsif (colnum==fieldcount+1) then # 'updated_at` and end of SQL
					t = Time.now
					sql+='\'' + t.strftime("%Y-%m-%d %H:%M:%S") + '\');'
					 
				end
						
			end #col
		
			puts sql
			dbh.query(sql)
			
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

	
	
	
	
	

