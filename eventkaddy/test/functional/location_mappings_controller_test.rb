# require 'test_helper'

# class LocationMappingsControllerTest < ActionController::TestCase
#   setup do
#     @location_mapping = location_mappings(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:location_mappings)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create location_mapping" do
#     assert_difference('LocationMapping.count') do
#       post :create, :location_mapping => @location_mapping.attributes
#     end

#     assert_redirected_to location_mapping_path(assigns(:location_mapping))
#   end

#   test "should show location_mapping" do
#     get :show, :id => @location_mapping.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @location_mapping.to_param
#     assert_response :success
#   end

#   test "should update location_mapping" do
#     put :update, :id => @location_mapping.to_param, :location_mapping => @location_mapping.attributes
#     assert_redirected_to location_mapping_path(assigns(:location_mapping))
#   end

#   test "should destroy location_mapping" do
#     assert_difference('LocationMapping.count', -1) do
#       delete :destroy, :id => @location_mapping.to_param
#     end

#     assert_redirected_to location_mappings_path
#   end
# end
