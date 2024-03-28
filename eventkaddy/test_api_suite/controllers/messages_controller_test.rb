require 'test_helper'
#to see test output use $stdout.puts json_response

class MessagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @attendee = attendees(:realistic)
    @attendee_id = @attendee.id
    @account_code = @attendee.account_code
    @event_id = @attendee.event_id
    @app_message_thread_id = attendees_app_message_threads(:one).id
    @message_thread_id = app_messages(:one).id
    @msg = { title: "test",
             new_content: "htest",
             msg_content: "htest",
             id: "1",
             recipients: [{
                id: "1111",
                type: "group",
                title: "htest",
                new_content: "htest",
                msg_time: "htest"
              }]
            }
    @init_mode = "true"
  end

  # test can be used when method is updated to send a different JSON format (see format sent by app)
  # test "sync_push" do
  #   uri = URI("/v1/messages/sync/push?")
  #   post uri, params: {message: @msg, api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id, init_mode: @init_mode}, as: :json, headers: headers_call
  #   assert_response :success
  #   assert_equal 3, json_response.length
  #   assert json_response["status"]
  #   refute json_response["message_thread_id"].blank?
  # end

  test "sync_push_read_status" do
    uri = URI("/v1/messages/sync/push_read_status")
    post uri, params: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id,read_status:"true", app_message_thread_id: @app_message_thread_id}, as: :json, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

  test "sync_delete" do
    uri = URI("/v1/messages/sync/delete")
    post uri, params: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id, app_message_thread_id: @app_message_thread_id}, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

  test "sync_list_all" do
    uri = URI("/v1/messages/sync/list_all")
    post uri, params: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id}, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("message_sync_list_all", json_response["messages"][0])
    refute json_response["messages"][0]["message_recipients"][0].blank?
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

  test "refresh_thread" do
    uri = URI("/v1/messages/sync/refresh_thread")
    post uri, params: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id, message_thread_id: @message_thread_id}, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

end
