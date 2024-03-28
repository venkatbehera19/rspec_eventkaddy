require "test_helper"

class SessionPollsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get session_polls_index_url
    assert_response :success
  end
end
