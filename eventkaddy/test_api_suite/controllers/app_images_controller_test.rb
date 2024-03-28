require 'test_helper'
#to see test output use $stdout.puts json_response

class AppImagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    Rails.cache.clear
    app_images = app_images(:one)
    @event_id = app_images.event_id
    app_images_2 = app_images(:two)
    @event_id_2 = app_images_2.event_id
  end
    
  test "list_templates" do
    uri = URI("/v1/app_images/list_templates")
    post uri, params: {"api_proxy_key" => "#{api_pass}", "event_id" => "#{@event_id}"}, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("app_image", json_response)
    match_schema("app_image-data", json_response["app_image_templates"][0])
  end

  test "fetch_sized_image_url" do
    uri = URI("/v1/app_images/fetch_sized_image_url")
    post uri, params: {"api_proxy_key" => "#{api_pass}", "event_id" => "#{@event_id_2}", "device_type" => "android", "image_type" => "jpg", "template_app_image_id" => "2"}, headers: headers_call
    assert_response :success
    assert_equal 3, json_response.length
    match_schema("app_image_fetched_sized", json_response)
  end
 
end
