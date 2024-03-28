# require 'test_helper'

# class LocationMappingTypesControllerTest < ActionController::TestCase
#   setup do
#     @location_mapping_type = location_mapping_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:location_mapping_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create location_mapping_type" do
#     assert_difference('LocationMappingType.count') do
#       post :create, :location_mapping_type => @location_mapping_type.attributes
#     end

#     assert_redirected_to location_mapping_type_path(assigns(:location_mapping_type))
#   end

#   test "should show location_mapping_type" do
#     get :show, :id => @location_mapping_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @location_mapping_type.to_param
#     assert_response :success
#   end

#   test "should update location_mapping_type" do
#     put :update, :id => @location_mapping_type.to_param, :location_mapping_type => @location_mapping_type.attributes
#     assert_redirected_to location_mapping_type_path(assigns(:location_mapping_type))
#   end

#   test "should destroy location_mapping_type" do
#     assert_difference('LocationMappingType.count', -1) do
#       delete :destroy, :id => @location_mapping_type.to_param
#     end

#     assert_redirected_to location_mapping_types_path
#   end
# end
