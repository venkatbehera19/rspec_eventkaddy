require 'test_helper'
#to see test output use $stdout.puts json_response

class NotesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @attendee = attendees(:realistic)
    @event_id = @attendee.event_id
    @attendee_account_code = @attendee.account_code
    @note_id = attendee_text_uploads(:one).id
    @session_id = sessions(:realistic).id
    @session_code = sessions(:realistic).session_code
    @exhibitor_name = exhibitors(:realistic).company_name
    @exhibitor_id = exhibitors(:realistic).id
    @count = AttendeeTextUpload.count
    @note = {type: "note", session_id: @session_id, exhibitor_id: @exhibitor_id, title: "the new title", content: "my July content", id: "122", session_code: @session_code, exhibitor_name: @exhibitor_name }
  end

  test "sync_fetch_single" do
    uri = URI("/v1/notes/sync/fetch_single")
     post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, note_id: @note_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 8, json_response.length
    match_schema("fetch_single_note", json_response)
  end

  test "sync_list" do
    uri = URI("/v1/notes/sync/list")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("fetch_note", json_response)
    match_schema("fetch_note-data", json_response["notes"][0])
  end

  test "sync_update" do
    uri = URI("/v1/notes/sync/update")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, note:@note}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 7, json_response.length
    match_schema("update_note", json_response)
    assert_equal @count + 1, AttendeeTextUpload.count
  end

  test "sync_delete" do
    uri = URI("/v1/notes/sync/delete")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, note_id: @note_id}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert_equal @count - 1, AttendeeTextUpload.count
  end

  test "sync_set_email" do
    uri = URI("/v1/notes/sync/set_email")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @attendee_account_code, note_id: @note_id, email: "test@test.com"}, as: :json, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

end