
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

def responses_by_survey
  Response.find_by_sql([
    "SELECT s.title,
            se.title AS session_title,
            se.session_code,
            GROUP_CONCAT( DISTINCT CONCAT( sp.first_name, ' ', sp.last_name) SEPARATOR ', ') AS speakers,
            se.date,
            se.start_at,
            se.end_at,
            s.id AS survey_id,
            ss.heading,
            ss.subheading,
            se.id AS session_id,
            ta.id AS target_attendee_id,
            at.account_code,
            at.first_name,
            at.last_name,
            ta.first_name AS lead_first_name,
            ta.last_name AS lead_last_name,
            r.updated_at,
       GROUP_CONCAT(
           CONCAT( ss.order, '.', q.order, '. ', q.question) ORDER BY ss.order, q.order SEPARATOR '||'
       ) AS survey_questions,
       GROUP_CONCAT(
           CONCAT( ss.order, '^^', q.order, '^^', IFNULL( r.response, IFNULL(r.rating, IFNULL(a.answer, ''))) ) ORDER BY ss.order, q.order SEPARATOR '||'
       ) AS survey_answers,
       GROUP_CONCAT(
           IFNULL(a.correct, '') ORDER BY ss.order, q.order SEPARATOR '||'
       ) AS corrects,
       s.survey_type_id
      FROM responses AS r
      LEFT JOIN survey_responses AS sr ON sr.id               = r.survey_response_id
      LEFT JOIN surveys          AS s  ON s.id                = sr.survey_id
      LEFT JOIN questions        AS q  ON q.id                = r.question_id
      LEFT JOIN answers          AS a  ON a.id                = r.answer_id
      LEFT JOIN survey_sections  AS ss ON q.survey_section_id = ss.id
      LEFT JOIN attendees        AS at ON at.id               = sr.attendee_id
      LEFT JOIN sessions         AS se ON se.id               = sr.session_id
      LEFT JOIN sessions_speakers AS sesp ON sesp.session_id    = sr.session_id
      LEFT JOIN speakers          AS sp ON sp.id              = sesp.speaker_id
      LEFT JOIN attendees        AS ta ON ta.id               = sr.target_attendee_id
      WHERE r.event_id=? AND survey_type_id=3
      GROUP BY sr.id
      ORDER BY s.id, se.id, at.id, se.id, ta.id, ss.order, q.order, a.order", EVENT_ID]
    )
end

job.start {

  utc_offset = Event.find( EVENT_ID ).utc_offset || "+00:00"


  last_survey_id = nil
  responses      = responses_by_survey

	job.update!(total_rows:responses.length, status:'Processing Rows')

  raise "No survey responses were found for sessions in this event." if responses.length == 0


  filename = "session_surveys.xlsx"
  path     = Rails.root.join('public', 'event_data', EVENT_ID.to_s, 'generated_session_survey', filename)
  dirname  = File.dirname( path )
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  p = Axlsx::Package.new
  wb = p.workbook
  p.use_autowidth = true

  wb.styles do |s|
    black_cell = s.add_style :bg_color => "00", :fg_color => "FF", :sz => 14, :alignment => { :horizontal=> :center }

    wb.add_worksheet(name: "Session Survey Results") do |sheet|

      # could add speakers concatonated
      responses.each do |r|
        job.row = job.row + 1
        job.write_to_file if job.row % job.rows_per_write == 0
        # headers and current row for new survey
        unless r.survey_id == last_survey_id
          last_survey_id = r.survey_id
          heads = ["Session Title", "Session Code", "Speakers", "Session Date", "Session Time", "Survey Name", "First Name", "Last Name"].concat(
            # group_by then map to avoid duplicate questions
            r.survey_questions.split('||').group_by {|a| a[0..4] }.values.map {|a| a[0] }
          ).concat(
            ["Response Last Updated At", "(Local Time) Response Last Updated At"]
          )

          style = heads.map {|h| black_cell }
          sheet.add_row heads, :style => style
        end
        row = [r.session_title, r.session_code, r.speakers, r.date, "#{ r.start_at && r.start_at.strftime('%T')} - #{r.end_at && r.end_at.strftime('%T')}", r.title, r.first_name, r.last_name].
          concat(
            r.survey_answers.
              split('||').
              group_by {|a| a[0..4] }.
              values.
              map {|a|
                # remove the section and question order values
                a.map{|x| x.split('^^').last}.join(', ')
              }
          ).concat(
            [r.updated_at.to_s,
             Time.parse("#{r.updated_at.strftime('%Y-%m-%d %H:%M:%S')}Z").localtime(utc_offset).to_s]
          )
          sheet.add_row row
      end # each response
    end # each sheet
  end # each style

  p.serialize( path )

  linkname = "Download Session Surveys Report"

  job.add_info "<a class='btn btn-success btn-sm' href='#{path.to_s.split('public')[1]}'>#{linkname}</a>"

} # Job.start
