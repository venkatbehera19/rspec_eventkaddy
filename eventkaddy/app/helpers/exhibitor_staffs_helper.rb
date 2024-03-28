require 'uri'
require 'net/http'
require 'openssl'
require 'json'
module ExhibitorStaffsHelper
  URL = URI("https://api.daily.co/v1/rooms")

  def create_room(exhibitor_staff)
    name = exhibitor_staff.room_name
    http = Net::HTTP.new(URL.host, URL.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(URL)
    request["content-type"] = 'application/json'
    request["authorization"] = 'Bearer a24c0ca558a38db2a25b30d2e6089677f63ef03ee8b21206848b16db3ad58c1d'
    if name
       request.body = "{\"name\":\"#{name}\",\"properties\":{\"max_participants\":6,\"autojoin\":false,\"enable_knocking\":true,\"enable_screenshare\":true,\"enable_chat\":true,\"start_video_off\":false,\"start_audio_off\":false}}"
    else
       request.body = "{\"properties\":{\"max_participants\":6,\"autojoin\":false,\"enable_knocking\":true,\"enable_screenshare\":true,\"enable_chat\":true,\"start_video_off\":false,\"start_audio_off\":false}}"
    end
    response = http.request(request)
    puts response.read_body
    JSON.parse(response.body)["url"]
  end

  def delete_room(room_name)
    url = URI("https://api.daily.co/v1/rooms/#{room_name}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Delete.new(url)
    request["content-type"] = 'application/json'
    request["authorization"] = 'Bearer a24c0ca558a38db2a25b30d2e6089677f63ef03ee8b21206848b16db3ad58c1d'
    request.body = "{\"properties\":{\"max_participants\":6,\"autojoin\":false,\"enable_knocking\":true,\"enable_screenshare\":true,\"enable_chat\":true,\"start_video_off\":false,\"start_audio_off\":false}}"

    response = http.request(request)
  end

  def get_active_participants
    url = URI("https://api.daily.co/v1/presence")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["content-type"] = 'application/json'
    request["authorization"] = 'Bearer a24c0ca558a38db2a25b30d2e6089677f63ef03ee8b21206848b16db3ad58c1d'
    response = http.request(request)
    puts response.read_body
    hasho = JSON.parse(response.body)
  end

end
