require_relative '../settings.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID     = ARGV[0]
JOB_ID       = ARGV[1]
FILENAME     = ARGV[2]
SHEETNAME    = ARGV[3]
LINKLABEL    = ARGV[4]
FETCH_METHOD = ARGV[5]

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:@db_name, row:0, status:'In Progress')
end

job.start {
  path = Rails.root.join('public', 'event_data', EVENT_ID.to_s, 'reports', FILENAME)
  job.xlsx_report path, SHEETNAME, LINKLABEL, ReportsController.send(FETCH_METHOD, EVENT_ID, job )
}


