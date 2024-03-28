require 'test_helper'
#to see test output use $stdout.puts json_response

class CustomListsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @custom_list = custom_lists(:one)
    @event_id = @custom_list.event_id
    @custom_list_count = CustomList.count
  end


  test "mobile_data returns custom_lists" do
    uri = URI("/v1/custom_lists/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @custom_list_count, json_response.length
    match_schema("custom_list", json_response[0])
  end

end
