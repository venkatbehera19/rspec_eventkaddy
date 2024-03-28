require 'test_helper'
require 'json-schema'
#to see test output use $stdout.puts json_response

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event_id = sessions(:realistic).event_id
    @session_count = Session.count
    @sessions_speaker_count = SessionsSpeaker.count
    @sessions_sponsor_count = SessionsSponsor.count
  end

  test "mobile_data returns sessions" do
    uri = URI("/v1/sessions/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("session_mobile_data", json_response[0])
  end

  test "mobile_data_sessions_only returns sessions" do
    uri = URI("/v1/sessions/mobile_data_sessions_only/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @session_count, json_response.length
    match_schema("session", json_response[0])
  end

  test "mobile_data_sessions_speakers returns sessions_speaker" do
    uri = URI("/v1/sessions/mobile_data_sessions_speakers/#{@event_id}/1")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @sessions_speaker_count, json_response.length
    match_schema("sessions_speaker", json_response[0])
  end

  test "mobile_data_session_leaf_tags returns sessions" do
    uri = URI("/v1/sessions/tags/leaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length #returns leaf and nonleaf tags
    match_schema("session_leaf_tag", json_response[0])
  end

  test "mobile_data_session_nonleaf_tags returns sessions" do
    uri = URI("/v1/sessions/tags/nonleaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("session_nonleaf_tag", json_response[0])
  end

  test "mobile_data_sessions_sponsors returns sessions" do
    uri = URI("/v1/sessions/sponsors/mobile_data/#{@event_id}/1")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @sessions_sponsor_count, json_response.length
    match_schema("sessions_sponsor", json_response[0])
  end
  
end

