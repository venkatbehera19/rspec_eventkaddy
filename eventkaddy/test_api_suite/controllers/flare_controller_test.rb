require 'test_helper'
#to see test output use $stdout.puts json_response

class NotesControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @user_id = users(:best_user).id
    @event_id = events(:one).id
  end

  test "flare events" do
    uri = URI("/v1/flare/events")
    post uri, params: { api_proxy_key: "#{api_pass}"}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    assert json_response["status"]
    match_schema("flare_event", json_response)
  end

  test "flare_users" do
    uri = URI("/v1/flare/users")
    post uri, params: { api_proxy_key: "#{api_pass}", user_id: @user_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    assert json_response["status"]
    match_schema("flare_user", json_response)
  end

  test "flare_users_for_events" do
    uri = URI("/v1/flare/users_for_events")
     post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    assert json_response["status"]
    match_schema("flare_users_for_event", json_response)
    match_schema("flare_users_for_events-data", json_response["data"][0])
  end
end