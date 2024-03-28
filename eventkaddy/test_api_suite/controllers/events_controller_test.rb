require 'test_helper'
#to see test output use $stdout.puts json_response

class EventsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @event = events(:one)
    @event_id = @event.id
    @user_name = @event.diy_username
    @user_pass = @event.diy_user_pass
    # @file = file_fixture('cats.jpeg')
  end

  test "mobile_data returns events" do
    uri = URI("/v1/events/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("event", json_response[0])
  end

  test "fetch_cms_time returns time" do
    uri = URI("/v1/events/fetch_cms_time?api_proxy_key=#{api_pass}")
    post uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("event_cms_current_time", json_response)
    assert json_response["status"]
  end

  test "mobile_data_cordova_settings" do
    uri = URI("/v1/events/mobile_data_cordova_settings/#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 5, json_response.length
    match_schema("events_mobile_data_cordova_settings", json_response)
  end

  test "mobile_data_cordova_settings_overrides_v2" do
    uri = URI("/v1/events/mobile_data_cordova_setting_overrides_v2")
    post uri, params: {event_id:@event_id, api_proxy_key:api_pass}, headers: headers_call
    assert_response :success
    assert_equal 4, json_response.length
    match_schema("events_mobile_data_cordova_setting_overrides_v2", json_response)
    assert json_response["status"]
  end

  test "mobile_data_init_data gets data" do
    uri = URI("/v1/events/mobile_data_init_data/#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 7, json_response.length
    match_schema("mobile_data_init_data_event", json_response)
    assert_equal "Best Event", json_response["event_name"]
  end

  test "multi_event_list gets data" do
    uri = URI("/v1/events/multi_event/list/0?org_name=Fiserv")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("multi_event", json_response[0])
  end

  test "diy_event_list gets data" do
    uri = URI("/v1/events/diy_event/list/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("diy_event", json_response[0])
  end

  test "diy_auth authenicates user" do
    uri = URI("/v1/events/diy_auth?api_key=#{api_pass}&user_name=#{@user_name}&user_pass=#{@user_pass}&event_id=#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    assert json_response["valid_user"]
  end

  test "photo_gallery_upload uploads photo" do
    uri = URI("/v1/events/photo_gallery_upload")
    post uri, params: {:file => fixture_file_upload('files/cats.jpeg', 'image/jpeg'), proxy_key:api_pass, event_id:@event_id}, headers: headers_call
    assert_response :success
  end

end
