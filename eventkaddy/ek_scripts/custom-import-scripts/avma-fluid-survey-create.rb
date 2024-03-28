###########################################
#Ruby script to generate fluid surveys
#with session data from a single template
#survey
###########################################

require 'roo'
require 'mysql2'
require 'date'

require 'json'
require 'curb'

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

#setup variables
FS_USERNAME    = 'avma_ce@avma.org'
FS_PASSWORD    = 'avmacesurvey'
FS_CLIENT_NAME = 'AVMA 2015'
event_id       = 48

def letter?(letter)
  (letter =~ /[[:alpha:]]/) === 0
end


### create a custom survey collector for each session and push it to fluid survey ###
Session.where(event_id:event_id).each do |session|

  if letter?(session.session_code)
    fs_survey_id = '826210' #2015 AVMA Event Survey
  else
    fs_survey_id = '826211' #2015 AVMA CE Session Survey
  end
  fs_create_collector_url = "https://fluidsurveys.com/api/v2/surveys/#{fs_survey_id}/collectors/"

  #generate list of speakers
  speakers = ''
  session.speakers.each_with_index do |speaker,i|
    if (session.speakers[i+1]==nil) then
      speakers += "#{speaker.honor_prefix} #{speaker.first_name} #{speaker.last_name} #{speaker.honor_suffix}"
    else
      speakers += "#{speaker.honor_prefix} #{speaker.first_name} #{speaker.last_name} #{speaker.honor_suffix} | "
    end
  end

  data = "name=#{session.session_code}"

  result = Curl::Easy.http_post(fs_create_collector_url,data) do |curl|
    curl.http_auth_types = :basic
    curl.username        = FS_USERNAME
    curl.password        = FS_PASSWORD
  end
  puts result.body_str

  result                  = JSON.parse(result.body_str)
  fs_update_collector_url = fs_create_collector_url + result["id"].to_s + '/'
  survey_url              = result["url"]

  #update collector with variable values
  data = "session_code=#{session.session_code}&session_title=#{session.title}&speakers=#{speakers}"

  puts data
  puts fs_update_collector_url

  result = Curl::Easy.http_put(fs_update_collector_url,data) do |curl|
    curl.http_auth_types = :basic
    curl.username        = FS_USERNAME
    curl.password        = FS_PASSWORD
  end

  puts result.body_str

  session.update!(survey_url:survey_url)

end

