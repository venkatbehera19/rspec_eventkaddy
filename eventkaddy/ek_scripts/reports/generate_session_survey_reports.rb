###########################################
# Generate xls sheets based on survey
# responses.
###########################################

require_relative '../settings.rb'
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'
require 'axlsx'
require 'axlsx_rails'

ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",
	:host     => @db_host,
	:username => @db_user,
	:password => @db_pass,
	:database => @db_name)


EVENT_ID = ARGV[0]
JOB_ID   = ARGV[1]

if JOB_ID
	job = Job.find JOB_ID
	job.update!(original_file:'EK Database', row:0, status:'In Progress')
end



job.start {

  utc_offset = Event.find( EVENT_ID ).utc_offset || "+00:00"

  @sessions = Session.select('sessions.id, title, session_code, date, start_at, end_at').joins('RIGHT JOIN survey_responses ON survey_responses.session_id = sessions.id').where('sessions.event_id=?', EVENT_ID)
	@sessions = @sessions.select {|s| s.surveys.length > 0}

  raise "No survey responses were found for sessions in this event." if @sessions.length == 0

	total_rows = @sessions.length

	job.update!(total_rows:total_rows, status:'Processing Rows')

  @sessions.each do |session|

    @session = session

  	job.row = job.row + 1
  	job.write_to_file if job.row % job.rows_per_write == 0

    p = Axlsx::Package.new
    wb = p.workbook
    p.use_autowidth = true

    def add_basic_info(sheet, s)
      bold_cell = s.add_style :sz => 16
    	sheet.add_row ["Session Code: #{@session.session_code}"], style: bold_cell, :height => 30
    	sheet.add_row ["Title: #{@session.title}"], style: bold_cell, :height => 30
    	sheet.add_row ["Speakers: #{@session.speakers.map {|s| s.full_name}.join(', ')}"], style: bold_cell, :height => 30
    	sheet.add_row ["Date: #{@session.date}"], style: bold_cell, :height => 30
    	sheet.add_row ["Time: #{@session.start_at.strftime('%T')} - #{@session.end_at.strftime('%T')}"], style: bold_cell, :height => 30
    end

    def add_headers(sheet, s)
    	black_cell = s.add_style :bg_color => "00", :fg_color => "FF", :sz => 14, :alignment => { :horizontal=> :left }
    	style = []
    	heads = ['Registration ID', 'Attendee Name']
			@session.surveys.first.questions
				.order('questions.survey_section_id, questions.order')
				.each {|q| heads << q.question; @question_ids << q.id }
    	heads << "Response Last Updated At"
      heads << "(Local Time) Response Last Updated At"
    	heads.each {|h| style << black_cell }
    	sheet.add_row heads, :style => style
    end

    @question_ids = []

    wb.styles do |s|

    	wb.add_worksheet(name: "Survey Results") do |sheet|

    		add_basic_info sheet, s
    		sheet.add_row []
    		add_headers sheet, s

    		SurveyResponse.where(session_id:@session.id).order('attendee_id').each do |sr|

    			attendees = Attendee.where(id:sr.attendee_id)
          if attendees.length == 0
            job.warnings = job.warnings.blank? ? "Attendee ID #{sr.attendee_id} could not be found." : job.warnings + '||' + "Attendee ID #{sr.attendee_id} could not be found."
          	job.write_to_file
            next
          end
          attendee = attendees.first
    			responses = sr.responses
    			row = [attendee.account_code, attendee.full_name]

          next if responses.blank?

          row.concat Answer.answers_as_array( @question_ids, responses ) 
    			row << sr.updated_at.to_s
          row << Time.parse("#{sr.updated_at.strftime('%Y-%m-%d %H:%M:%S')}Z").localtime(utc_offset).to_s

    			sheet.add_row row
    		end
    	end
    end

    dirname = Rails.root.join('public', 'event_data', EVENT_ID.to_s, 'session_survey_reports')

    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    p.serialize("public/event_data/#{EVENT_ID}/session_survey_reports/#{@session.session_code}_#{@session.title[0..10].gsub(/\//,'')}.xlsx")

  end

  job.update!(status:'Creating .zip archive.')
  job.write_to_file

  Survey.bundle_session_survey_files EVENT_ID

} # Job.start
