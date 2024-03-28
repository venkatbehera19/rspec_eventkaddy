require 'test_helper'
#to see test output use $stdout.puts json_response

class FeedbacksControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @feedbacks = feedbacks(:one)
    @event_id = @feedbacks.event_id
    @speaker_id = @feedbacks.speaker_id
    @session_id = @feedbacks.session_id
    @feedback = {   speaker_id: @speaker_id, 
                    session_id: @session_id, 
                    rating: "3", 
                    comment: "a great comment" }
  end

  test "mobile_data returns exhibitors" do
    uri = URI("/v1/feedbacks/push_speaker_feedback")
    post uri, params: { api_proxy_key: "#{api_pass}", event_id: @event_id, feedback: @feedback}, as: :json,  headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length
    match_schema("feedback", json_response)
    assert json_response['status']
  end
 
end
