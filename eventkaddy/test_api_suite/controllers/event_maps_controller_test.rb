require 'test_helper'
#to see test output use $stdout.puts json_response

class EventMapsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @event_map = event_maps(:one)
    @event_id = @event_map.event_id
    @event_map_count = EventMap.count
  end

  test "mobile_data returns event_map" do
    uri = URI("/v1/event_maps/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @event_map_count, json_response.length
    match_schema("event_map", json_response[0])
  end

end
