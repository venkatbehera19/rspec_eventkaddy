require 'test_helper'
#to see test output use $stdout.puts json_response

class SurveysControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear

    @account_code = attendees(:realistic).account_code
    @event_id = survey_responses(:first_survey_response).event_id
    @session_id = survey_responses(:first_survey_response).session_id
    @survey_id = survey_responses(:first_survey_response).survey_id
    @responses = [{
      question_id: questions(:one).id,
      rating: "1",
      session_id: @session_id,
      survey_id: @survey_id,
      response: "great question",
      answer_id: answers(:one).id
    }]
  end

  test "post_survey_responses updates surveys" do
    uri = URI("/v1/surveys_api/post_survey_responses")
    post uri, params: {json: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id, responses: @responses}}, as: :json, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    assert json_response["status"]
    assert json_response["error_messages"].blank?
  end

  test "surveys_mobile_data get survey info" do
    uri = URI("/v1/surveys_api/surveys_mobile_data/#{@event_id}/1")
    get uri, headers: headers_call
    assert_response :success
    match_schema("survey", json_response[0])
    match_schema("survey_section", json_response[0]["sections"][0])
    match_schema("survey_question", json_response[0]["sections"][0]["questions"][0])
    match_schema("survey_answer", json_response[0]["sections"][0]["questions"][0]["answers"][0])
  end

  test "surveys_response_mobile_data get attendee response info" do
    uri = URI("/v1/surveys_api/survey_responses_mobile_data/#{@event_id}/1?attendee_account_code=#{@account_code}")
    get uri, headers: headers_call
    assert_response :success
    match_schema("survey_response", json_response[0])
  end

  test "surveys_api gets survey info" do
    uri = URI("/v1/surveys_api/get_survey")
    post uri, params: {api_proxy_key: "#{api_pass}", survey_id: @survey_id}, as: :json, headers: headers_call
    assert_response :success
    assert json_response["status"]
    match_schema("survey", json_response["survey"])
    match_schema("survey_section", json_response["survey"]["sections"][0])
    match_schema("survey_question", json_response["survey"]["sections"][0]["questions"][0])
    match_schema("survey_answer", json_response["survey"]["sections"][0]["questions"][0]["answers"][0])
  end


  test "get_single_survey gets survey info" do
    uri = URI("/v1/surveys_api/get_single_survey")
    post uri, params: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id:@event_id, session_id:@session_id, survey_id: @survey_id}, as: :json, headers: headers_call
    assert_response :success
    assert json_response["status"]
    assert json_response["error_messages"].blank?
    match_schema("survey_get_single_survey", json_response["survey"])
    match_schema("survey_section", json_response["survey"]["sections"][0])
    match_schema("survey_question", json_response["survey"]["sections"][0]["questions"][0])
    match_schema("survey_answer", json_response["survey"]["sections"][0]["questions"][0]["answers"][0])
  end

  test "survey_results gets survey info" do
    uri = URI("/v1/surveys_api/survey_results")
    post uri, headers: headers_call
    assert_response :success
  end

end




