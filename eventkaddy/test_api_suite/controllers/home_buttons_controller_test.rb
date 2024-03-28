require 'test_helper'
#to see test output use $stdout.puts json_response

class HomeButtonsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @home_button = home_buttons(:one)
    @event_id = @home_button.event_id
    @home_button_count = HomeButton.count
  end

  test "mobile_data returns home_button" do
    uri = URI("/v1/home_buttons/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @home_button_count, json_response.length
    match_schema("home_button", json_response[0])
  end

end
