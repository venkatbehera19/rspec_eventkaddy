require 'test_helper'
#to see test output use $stdout.puts json_response

class AppGameControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    Rails.cache.clear
    @event_id = events(:one).id
    @attendee_account_code = attendees(:realistic).account_code
    @app_badge_id = app_badges(:one).id
    @count = AttendeesAppBadge.count
  end

  test "fetch_leaderboard" do
    uri = URI("/v1/app_game/fetch_leaderboard?event_id=#{@event_id}&#{@attendee_account_code}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("fetch_leaderboard", json_response[0])
  end

  test "fetch_app_badges" do
    uri = URI("/v1/app_game/fetch_app_badges")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("fetch_app_badge", json_response)
    match_schema("fetch_app_badge-data", json_response["badges"][0])
  end

  test "fetch_app_badge_tasks" do
    uri = URI("/v1/app_game/fetch_app_badge_tasks")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, app_badge_id: @app_badge_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("fetch_app_badge_task", json_response)
    match_schema("fetch_app_badge_task-data", json_response["badge_tasks"][0])   
  end

  test "push_app_badge" do
    uri = URI("/v1/app_game/push_app_badge")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, app_badge_id: 5, points_collected:"7", num_badge_tasks_complete: "10" }, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 4, json_response.length
    match_schema("push_app_badge", json_response)
    assert_equal @count + 1 , AttendeesAppBadge.count
  end

end
