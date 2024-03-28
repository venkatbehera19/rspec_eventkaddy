require 'test_helper'
#to see test output use $stdout.puts json_response

class NotificationsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @attendee = attendees(:realistic)
    @event_id = @attendee.event_id
    @attendee_account_code = @attendee.account_code
    @notification_id = notifications(:three).id
    @count = AttendeesReadNotification.count
  end

  test "mobile_data" do
    uri = URI("/v1/notifications/mobile_data/#{@event_id}?attendee_account_code=#{@attendee_account_code}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response[0]["read_status"]
    match_schema("notification", json_response[0]["notf_result"])
  end

  test "push_read_status" do
    uri = URI("/v1/notifications/push_read_status")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, notification_id: @notification_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert_equal @count + 1 , AttendeesReadNotification.count
  end

end
