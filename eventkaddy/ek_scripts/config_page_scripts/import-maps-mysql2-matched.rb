###########################################
#Ruby script to import map data from
#spreadsheet (ODS) into EventKaddy CMS
###########################################
require 'roo'
require_relative '../settings.rb' #config

#for active record usage
require 'active_record'

#load the rails 3 environment
require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name
)

#other gems needed, but don't have to be requried above
 	#gem ruby-mysql
	#gem 'google-spreadsheet-ruby'
	#gem 'rubyzip2'

#from PHP land
def addslashes(str)
  str.gsub(/['"\\\x0]/,'\\\\\0')
end

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
SPREADSHEET_FILE = ARGV[1] #maps-data.ods, bobs-maps.ods, etc
JOB_ID           = ARGV[2]
USER_ID          = ARGV[3]

if JOB_ID
	job = Job.find JOB_ID
	job.update!(original_file:SPREADSHEET_FILE, row:0, status:'In Progress')
end

@error_count     = 0
@error_log       = ''


colLetter=['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ']


job.start {

	#open the spreadsheet
	if (SPREADSHEET_FILE.match(/.xlsx/))
		oo = Roo::Excelx.new(SPREADSHEET_FILE)
	elsif ( SPREADSHEET_FILE.match(/.xls/) )
		oo = Roo::Excel.new(SPREADSHEET_FILE)
	elsif ( SPREADSHEET_FILE.match(/.ods/) )
		oo = Roo::Openoffice.new(SPREADSHEET_FILE)
	else
		puts "Spreadsheet format not supported"
		exit
	end

	#process all the sheets
	oo.sheets.each do |sheet|

		puts "--------- Processing sheet: #{sheet} ------------\n"
		oo.default_sheet = sheet

		fields     = []
		fieldcount = 0
		1.upto(1) do |row|
			colLetter.each do |col|

				if (oo.cell(row,col)!=nil) then
					fields[fieldcount] = oo.cell(row,col)
					fieldcount += 1
				end

			end #col
		end #row

		puts fields.inspect + "\n"

		nonexistant_columns = []

		fields.each_with_index do |f, i|
			case f.downcase
			when 'location name'
				@location_name_col = i
			when 'map filename'
				@map_filename_col  = i
			when 'x coordinate'
				@x_coordinate_col  = i
			when 'y coordinate'
				@y_coordinate_col  = i
			when 'map type'
				@map_type_col      = i
			else
				nonexistant_columns << f
				@error_count += 1
			end

		end

		if nonexistant_columns.length > 0
			generate_columns_error_log(nonexistant_columns, event_id)
			raise "The following columns are incorrectly named: #{nonexistant_columns.inspect}".red
		end

		colvals = []

		total_rows = oo.last_row - 1

		job.update!(total_rows:total_rows, status:'Processing Rows')

		2.upto(oo.last_row) do |row|

			job.row = job.row + 1
			job.write_to_file if job.row % job.rows_per_write == 0

			t = Time.now

			0.upto(fieldcount-1) do |colnum|

				if (oo.cell(row,colLetter[colnum])==nil)
					colvals[colnum] = ''
				else
					colvals[colnum] = oo.cell(row,colLetter[colnum])
				end

			end #col

			#column mappings
			pattern = Regexp.new('[a-zA-Z]',Regexp::IGNORECASE)
			if @location_name_col
				if (colvals[@location_name_col].to_s.match(pattern)) then #string detect
					location_name = addslashes(colvals[@location_name_col])
				else
					location_name = colvals[@location_name_col].to_i.to_s
				end
			else
				location_name = nil
			end

			@map_filename_col ? map_filename = colvals[@map_filename_col]      : map_filename = nil
			@x_coordinate_col ? x_pos        = colvals[@x_coordinate_col].to_i : x_pos        = nil
			@y_coordinate_col ? y_pos        = colvals[@y_coordinate_col].to_i : y_pos        = nil
			@map_type_col     ? map_type     = colvals[@map_type_col]          : map_type     = nil

			if map_type=='Exhibitor Map'
				map_type      = 2
				location_type = 2
			elsif map_type=='Session Map'
				map_type      = 1
				location_type = 1
			else
				map_type      = nil
				location_type = nil
			end

			puts "processing location name: #{location_name}"

			rows = EventFile.select('id').where(name:map_filename, event_id:event_id)
			if rows.length==0
				puts "-- creating event_file for map: #{map_filename} --\n"
        event_file = EventFile.create(event_id:event_id,name:map_filename,size:'',mime_type:'image/jpeg',path:"/event_data/#{event_id.to_s}/maps/#{map_filename}",event_file_type_id:2)
        map_event_file_id = event_file.id
      else
        map_event_file_id = rows.first.id
      end

			rows = EventMap.select('id').where(name:map_filename,event_id:event_id)

			if rows.length==0
				puts "-- creating event_map: #{map_filename} --\n"

        event_map = EventMap.create(event_id:event_id,map_event_file_id:map_event_file_id,name:map_filename,filename:map_filename,width:'',height:'',map_type_id:map_type)

				map_id = event_map.id
			else
				map_id = rows.first.id
			end

			puts "map_id : #{map_id}"
			rows =  LocationMapping.select('id, map_id').where(event_id:event_id,name:location_name)

			if rows.length==0
				puts "-- creating location_mapping: #{location_name} --\n"
        LocationMapping.create(event_id:event_id,map_id:map_id,name:location_name,mapping_type:location_type,x:x_pos,y:y_pos)
  		else
        puts "-- updating location_mapping: #{location_name} --\n"
        LocationMapping.find(rows.first.id).update!(map_id:map_id,x:x_pos,y:y_pos)
			end
		end #row
	end #sheet

} # Job.start






