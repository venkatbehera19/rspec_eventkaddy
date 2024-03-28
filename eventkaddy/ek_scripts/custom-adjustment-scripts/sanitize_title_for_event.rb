###########################################
#Custom Adjustment Script
#Sanitize title for event
#Required for AVMA 2019 as search missing sessions with apostrophes
###########################################

require 'mysql2'

require_relative '../settings.rb'
require_relative '../utility-functions.rb'

require 'active_record'

require_relative '../../config/environment.rb'


ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

EVENT_ID = 208


sessions = Session.where(event_id:EVENT_ID)

#taken for avma mobile
def sanitize_title(str)    
  sub_strs = str.split(' ')
  clean_str = ''
  sub_strs.each_with_index do |sub_str,i|
    if (i > 0); clean_str+= " #{sub_str.gsub(/\W/,'')}" end
    if (i == 0); clean_str+= "#{sub_str.gsub(/\W/,'')}" end
  end
  return clean_str
end

sessions.each do |s|
  sanitized_title = sanitize_title(s.title)
  puts sanitized_title
  s.update!(sanitized_title:sanitized_title)
end



