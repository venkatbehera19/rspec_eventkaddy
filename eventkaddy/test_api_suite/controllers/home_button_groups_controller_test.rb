require 'test_helper'
#to see test output use $stdout.puts json_response

class HomeButtonGroupsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @home_button_groups = home_button_groups(:one)
    @event_id = @home_button_groups.event_id
  end

  test "home_button_groups_mobile_data_socials" do
    uri = URI("/v1/home_button_groups/mobile_data/socials/#{@event_id}/1")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("home_button_groups_social", json_response[0])
  end
 
end
