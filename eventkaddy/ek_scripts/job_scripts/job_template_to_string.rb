require_relative '../settings.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

EVENT_ID           = ARGV[0]
JOB_ID             = ARGV[1]
FILENAME           = ARGV[2]
LINKLABEL          = ARGV[3]
TEMPLATE_PATH      = ARGV[4].dup # render to string does destructive methods on this argument

if JOB_ID
  job = Job.find JOB_ID
  job.update!(original_file:@db_name, row:0, status:'In Progress')
end

job.start {

  INSTANCE_VARIABLES = JSON.parse( ARGV[5] ) # here in case of failure to parse

  path = Rails.root.join('public', 'event_data', EVENT_ID.to_s, 'reports', FILENAME)

  dirname = File.dirname( path )
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  c = ActionController::Base.new
  event = Event.find EVENT_ID
  c.instance_variable_set "@event_id", EVENT_ID
  c.instance_variable_set "@event", event
  c.instance_variable_set "@job", job

  INSTANCE_VARIABLES.each do |key, val|
    c.instance_variable_set "@#{key}", val
  end

  xlsx = c.render_to_string(layout: false, handlers: [:axlsx], formats: [:xlsx], template: TEMPLATE_PATH, locals: {})

  File.open(path, "w", 0644) {|f| f.write xlsx }

  job.add_info "<a class='btn btn-success btn-sm' href='#{path.to_s.split('public')[1]}'>#{LINKLABEL}</a>"
}

