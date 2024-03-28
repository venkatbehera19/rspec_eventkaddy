require 'test_helper'
#to see test output use $stdout.puts json_response

class ScavengerHuntItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @scavenger_hunt_item = scavenger_hunt_items(:one)
    @event_id = @scavenger_hunt_item.event_id
    @scavenger_hunt_item_count = ScavengerHuntItem.count
    @attendee_scavenger_hunt_item_count = AttendeesScavengerHuntItem.count
    @account_code = attendees(:realistic).account_code
    @item_ids = ["1,2,3"]
  end

  test "mobile_data returns scavenger_hunt_items" do
    uri = URI("/v1/scavenger_hunt_items/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @scavenger_hunt_item_count, json_response.length
    match_schema("scavenger_hunt_item", json_response[0])
  end

  test "attendee_scavenger_hunts_mobile_data returns scavenger_hunt_items" do
    uri = URI("/v1/scavenger_hunt_items/attendees_scavenger_hunts_mobile_data/#{@event_id}/0/?attendee_account_code=KM021")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @scavenger_hunt_item_count, json_response.length
    match_schema("attendee_scavenger_hunt_item", json_response[0])
  end

  test "post_attendee_scavenger_hunts_items returns scavenger_hunt_items" do
    uri = URI("/v1/scavenger_hunt_items/post_attendees_scavenger_hunt_item")
    post uri, params: {json: {api_proxy_key: "#{api_pass}", attendee_account_code: @account_code, event_id: @event_id, item_ids:@item_ids}}, as: :json, headers: headers_call
    assert_response :success
    refute json_response["item_ids"].blank?
  end
  
end
