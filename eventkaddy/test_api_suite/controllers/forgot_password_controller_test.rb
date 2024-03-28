require 'test_helper'
#to see test output use $stdout.puts json_response

class ForgotPasswordControllerTest < ActionDispatch::IntegrationTest

  setup do
    @attendee_user_name = attendees(:realistic).username
    @event_id = attendees(:realistic).event_id
    @token = attendees(:realistic).token
    @default = "support@eventkaddy.net"
  end

  test "forgot_password_desktop" do
    uri = URI("/v1/forgot")
    get uri, headers: headers_call
    assert_response :success
  end

  # #retrieve_password (not in use)
  # test "retrieve password" do
  #   uri = URI("/v1/forgot_password/retrieve_password")
  #   get uri, headers: headers_call
  #   assert_response :success
  # end

  test "mobile_send_password_reset_confirmation" do
    uri = URI("/v1/forgot_password/mobile_send_password_reset_confirmation?event_id=#{@event_id}&proxy_key=#{api_pass}&user_name=#{@attendee_user_name}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
  end

  test "mobile_forgot_password" do
    uri = URI("/v1/forgot_password/mobile_forgot_password?event_id=#{@event_id}&user_name=#{@attendee_user_name}&token=#{@token}")
    get uri, headers: headers_call
    assert_response :success
  end

end
