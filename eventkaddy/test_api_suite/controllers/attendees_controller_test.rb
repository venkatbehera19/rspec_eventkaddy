require 'test_helper'
#to see test output use $stdout.puts json_response

class AttendeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @attendee = attendees(:realistic)
    @account_code_attendee_with_id = attendees(:need_id).account_code
    @event_id = @attendee.event_id
    @account_code = @attendee.account_code
    @attendee_account_code_2 = attendees(:barebones).account_code
    @attendee_id = @attendee.id
    @send_email = "hpkent@gmail.com"
    @attendee_count = Attendee.where(event_id:@event_id).count
    @survey_id = surveys(:first_survey).id
    @scav_hunt = scavenger_hunt_items(:one).id
    @scav_hunt_list = "#{scavenger_hunt_items(:one).id}, #{scavenger_hunt_items(:two).id}"
    @iattend_sessions = "Mycode201"
    @favourite_sessions = sessions(:realistic).session_code
    @favourite_exhibitors = exhibitors(:realistic).company_name
    @position = 'latitude => 12, longitude => 14'
    @qr_content = 'dummy'
    @toggle_name = 'messaging_opt_out'
    @toggle_value = 1
    @callback = ""
    @user_name = @attendee.username
    @user_pass = @attendee.password
    @attendee_scan = "attendee:#{@attendee_account_code_2}"
    @device = "android"
    @position = {latitude: 39.1, longitude: -86.2}
    @scan_count = AttendeeScan.count
    @gps_data_count = AttendeeGpsDataPoint.count
    @attendee_photo_count = EventFile.count
  end

  test "mobile_data returns attendees" do
    uri = URI("/v1/attendees/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @attendee_count, json_response.length
    match_schema("attendee", json_response[0])
  end

  test "mobile_data_attendee_leaf_tags returns attendees" do
    uri = URI("/v1/attendees/tags/leaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length #returns leaf and nonleaf tags
    match_schema("attendee_leaf_tag", json_response[0])
  end

  test "mobile_data_attendee_nonleaf_tags returns attendees" do
    uri = URI("/v1/attendees/tags/nonleaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("attendee_nonleaf_tag", json_response[0])
  end

  test "authenticateattendee" do
    uri = URI("/v1/attendees/authenticateattendee?proxy_key=#{api_pass}&callback=#{@callback}&user_name=#{@user_name}&user_pass=#{@user_pass}&event_id=#{@event_id}&device=#{@device}")
    get uri, headers: headers_call
    assert_response :success
    json = JSON.parse(response.body.to_json)
    match_schema("authenticate_attendee", json)
    assert json["valid_user"]
  end

  test "generate_ce_sessions_pdf_report" do
    uri = URI("/v1/attendees/generate_ce_sessions_pdf_report/#{@event_id}/#{@account_code}/#{@send_email}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("generate_ce_sessions_pdf_report", json_response[0])
  end

  test "attendee_sessions" do
    uri = URI("/v1/attendees/mobile_data/attendee_sessions?attendee_auth_val=#{@account_code}&event_id=#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("sessions_attendee", json_response[0])
    json_array = json_response[0].to_a
    assert_equal "Mycode201", json_array[0][1]
  end

  test "attendee_ce_sessions" do
    uri = URI("/v1/attendees/mobile_data/attendee_ce_sessions?attendee_auth_val=#{@account_code}&event_id=#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("sessions_attendee", json_response[0])
    json_array = json_response[0].to_a
    assert_equal "Mycode201", json_array[0][1]
  end

  test "attendee_session_survey_responses returns attendees" do
    uri = URI("/v1/attendees/mobile_data/attendee_session_survey_responses?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("sessions_survey", json_response)
    assert json_response["status"]
  end

  test "attendee_ce_session_survey_responses" do
    uri = URI("/v1/attendees/mobile_data/attendee_ce_session_survey_responses?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}&survey_id=#{@survey_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("sessions_survey", json_response)
    assert json_response["status"]
  end

  test "attendee_single_survey_responses" do
    uri = URI("/v1/attendees/mobile_data/attendee_single_survey_responses?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}&survey_id=#{@survey_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("sessions_survey", json_response)
    assert json_response["status"]
  end

  test "attendee_single_survey_correct_answers" do
    uri = URI("/v1/attendees/mobile_data/attendee_single_survey_correct_answers?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}&survey_id=#{@survey_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("survey_correct_answer", json_response)
    assert json_response["status"]
  end

  test "attendee_scavenger_hunt_item" do
    uri = URI("/v1/attendees/mobile_data/attendee_scavenger_hunt_item?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}&scav_hunt_item_id=#{@scav_hunt}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("attendee_scavenger_hunt", json_response)
    assert json_response["status"]
  end

  test "bulk_attendee_scavenger_hunt_items" do
    uri = URI("/v1/attendees/mobile_data/bulk_attendee_scavenger_hunt_items?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}&scav_hunt_item_ids=#{@scav_hunt_list}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    # $stdout.puts @scav_hunt_list
    match_schema("attendee_scavenger_hunt", json_response)
    assert json_response["status"]
    # $stdout.puts json_response
    # assert_equal 2, json_response["items"].length
  end

  test "/attendees/mobile_data/attendee_scan_attendee_count" do
    uri = URI("/v1/attendees/mobile_data/attendee_scan_attendee_count?attendee_auth_val=#{@account_code_attendee_with_id}&event_id=#{@event_id}&proxy_key=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 4, json_response.length
    match_schema("attendee_scan_attendee_count", json_response)
    assert json_response["status"]
    refute_equal 0, json_response["scan_count"]
  end

  test "/attendees/mobile_data/attendee_qa_submission_count" do
    uri = URI("/v1/attendees/mobile_data/attendee_qa_submission_count?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 4, json_response.length
    match_schema("attendee_qa_submission_count", json_response)
    assert json_response["status"]
    refute_equal 0, json_response["qa_count"]
  end

  test "attendee_iattend_ce_sessions" do
    uri = URI("/v1/attendees/mobile_data/attendee_iattend_ce_sessions?attendee_auth_val=#{@account_code}&event_id=#{@event_id}&proxy_secret=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("attendee_iattend_ce_session", json_response)
    json_array = json_response.to_a
    assert_equal [{"session_code"=>"Mycode201"}], json_array[0][1]
  end

  test "attendee_exhibitors" do
    uri = URI("/v1/attendees/mobile_data/attendee_exhibitors?attendee_auth_val=#{@account_code}&event_id=#{@event_id}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("attendees_exhibitor", json_response[0])
    json_array = json_response[0].to_a
    assert_equal "A realistic company", json_array[0][1]
  end

  test "iattend_list" do
    uri = URI("/v1/attendees/iattend/list?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("iattend_list", json_response)

  end

  test "iattend_update" do
    uri = URI("/v1/attendees/iattend/update?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}&iattend_sessions=#{@iattend_sessions}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    assert json_response["status"]
  end

  test "favouritessync_list" do
    uri = URI("/v1/attendees/favouritessync/list?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("favouritessync_list", json_response)
    assert json_response["status"]
  end

  test "favouritessync_update" do
    uri = URI("/v1/attendees/favouritessync/update?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}&favourite_sessions=#{@favourite_sessions}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    assert json_response["status"]
  end

  test "exhibitor_favouritessync_list_v2" do
    uri = URI("/v1/attendees/exhibitor_favouritessync/list/v2?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("exhibitors_favouritessync_list", json_response)
    assert json_response["status"]
  end

  test "exhibitor_favouritessync_update_v2" do
    uri = URI("/v1/attendees/exhibitor_favouritessync/update/v2?account_code=#{@account_code}&event_id=#{@event_id}&proxy_key=#{api_pass}&favourite_exhibitors=#{@favourite_exhibitors}")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    assert json_response["status"]
  end

  test "push_gps_data" do
    uri = URI("/v1/attendees/push_gps_data")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @account_code, position: @position}, as: :json, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("push_gps_data", json_response)
    assert json_response["status"]
    assert_equal @gps_data_count + 1, AttendeeGpsDataPoint.count
  end

  test "push_qr_code_data" do
    uri = URI("/v1/attendees/push_qr_code_data?attendee_account_code=#{@account_code}&event_id=#{@event_id}&api_proxy_key=#{api_pass}&qr_content=#{@qr_content}")
    post uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("push_gps_data", json_response)
    assert json_response["status"]
  end

  test "push_attendee_scan_data" do
    uri = URI("/v1/attendees/push_attendee_scan_data")
    post uri, params: {api_proxy_key: "#{api_pass}", event_id: @event_id, attendee_account_code: @account_code, scan_data:@attendee_scan}, as: :json, headers:headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("push_gps_data", json_response)
    assert json_response["status"]
    assert_equal @scan_count + 1, AttendeeScan.count
  end

  test "push_toggle" do
    uri = URI("/v1/attendees/push_toggle?attendee_account_code=#{@account_code}&event_id=#{@event_id}&api_proxy_key=#{api_pass}&toggle_name=#{@toggle_name}&toggle_value=#{@toggle_value}")
    post uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("push_gps_data", json_response)
    assert json_response["status"]
  end

  test "fetch_toggle" do
    uri = URI("/v1/attendees/fetch_toggle?attendee_account_code=#{@account_code}&event_id=#{@event_id}&api_proxy_key=#{api_pass}&toggle_name=#{@toggle_name}")
    post uri, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("fetch_toggle", json_response)
    assert json_response["status"]
  end

  #not working as hardcoded for event_50
  test "distance_travelled" do
    uri = URI("/v1/attendees/distance_travelled/#{@attendee_id}")
    get uri, headers: headers_call
    assert_response :success
    assert 0, response.body
  end

  test "verify attendee" do
    uri = URI("/v1/attendees/verify_attendee?attendee_account_code=#{@account_code}&event_id=#{@event_id}&api_proxy_key=#{api_pass}")
    get uri, headers:headers_call
    assert_response :success
    match_schema("attendees_verify_attendee", json_response)
    assert json_response["status"]
  end

  test "update_attendee_profile_photo" do
    uri = URI("/v1/attendees/update_attendee_profile_photo")
    post uri, params: {api_proxy_key: api_pass, event_id: @event_id, attendee_account_code: @account_code, :file => fixture_file_upload('files/cats.jpeg', 'image/jpeg')}, headers: headers_call
    assert_response :success
    assert json_response["status"]
    assert_equal @attendee_photo_count + 1, EventFile.count
  end

end

