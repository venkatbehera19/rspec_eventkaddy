require 'test_helper'
#to see test output use $stdout.puts json_response

class SpeakersControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    Rails.cache.clear
    @speaker = speakers(:Micky)
    @event_id = @speaker.event_id
    @speaker_count = Speaker.count
  end

  test "mobile_data returns speakers" do
    uri = URI("/v1/speakers/mobile_data_speakers_only/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @speaker_count, json_response.length
    match_schema("speaker", json_response[0])
  end
end
