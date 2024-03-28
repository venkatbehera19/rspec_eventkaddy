###########################################
# Custom Adjustment Script
# Add amazon secure file links to embedded_video_url column
# This adjustment is for bcbs 2018, and is intended to provide
# urls that will satisfy them security wise.
# embedded_video_url is intended for the video portal, and thus
# this script misuses the column as a hack for bcbs.
###########################################

require_relative '../settings.rb' #config
require_relative '../utility-functions.rb'
require 'active_record'
require_relative '../../config/environment.rb'

ActiveRecord::Base.establish_connection( :adapter => "mysql2", :host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name )

EVENT_ID = ARGV[0].to_i

# "/event_data/161/session_files/10815_Test_20180329111837.pdf".split('/').last # "10815_Test_20180329111837.pdf"
# "https://newcms.eventkaddy.net/event_data/118/session_notes/2290.pdf".split('/').last # "2290.pdf"
def to_amazon_link url
  # can't actually rely on url to be standardized. For some reason we sometimes have it in
  # a session_notes folder, sometimes a full link, sometimes a session_files folder...
  # So just simplify and try to extract only the filename
  # if url.include? "eventkaddy.net"
  #   url.gsub(
  #     /.*eventkaddy.net\/event_data\/\d*\/session_notes/,
  #     "https://s3-us-west-1.amazonaws.com/eventkaddy/event_id/#{EVENT_ID}/session_files"
  #   )
  # else
  #   url.gsub(
  #     /\/event_data\/\d*\/session_files/,
  #     "https://s3-us-west-1.amazonaws.com/eventkaddy/event_id/#{EVENT_ID}/session_files"
  #   )
  # end
  "https://s3-us-west-1.amazonaws.com/eventkaddy/event_id/#{EVENT_ID}/session_files/#{url.split('/').last}"
end

Session.where(event_id: EVENT_ID).where("session_file_urls IS NOT NULL AND session_file_urls != ''").each do |s|
  # must use update_attribute to ignore validation (check https string) on custom_fields_2
  s.update_attribute( 
   :custom_fields_2,
   JSON.parse(s.session_file_urls).map { |u| u["url"] = to_amazon_link u["url"]; u }.to_json
  )
end

