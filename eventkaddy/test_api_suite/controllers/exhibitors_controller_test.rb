require 'test_helper'
#to see test output use $stdout.puts json_response

class ExhibitorsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    @exhibitor = exhibitors(:realistic)
    @event_id = @exhibitor.event_id
    @exhibitor_count = Exhibitor.count
  end

  test "mobile_data returns exhibitors" do
    uri = URI("/v1/exhibitors/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal @exhibitor_count, json_response.length
    match_schema("exhibitor", json_response[0])
  end

  test "mobile_data_exhibitor_leaf_tags returns exhibitors" do
    uri = URI("/v1/exhibitors/tags/leaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 2, json_response.length #returns leaf and nonleaf tags
    match_schema("exhibitor_leaf_tag", json_response[0])
  end

  test "mobile_data_exhibitor_nonleaf_tags returns exhibitors" do
    uri = URI("/v1/exhibitors/tags/nonleaf/mobile_data/#{@event_id}/0")
    get uri, headers: headers_call
    assert_response :success
    assert_equal 1, json_response.length
    match_schema("exhibitor_nonleaf_tag", json_response[0])
  end

end
