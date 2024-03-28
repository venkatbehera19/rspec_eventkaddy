# require 'test_helper'

# class MapTypesControllerTest < ActionController::TestCase
#   setup do
#     @map_type = map_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:map_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create map_type" do
#     assert_difference('MapType.count') do
#       post :create, :map_type => @map_type.attributes
#     end

#     assert_redirected_to map_type_path(assigns(:map_type))
#   end

#   test "should show map_type" do
#     get :show, :id => @map_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @map_type.to_param
#     assert_response :success
#   end

#   test "should update map_type" do
#     put :update, :id => @map_type.to_param, :map_type => @map_type.attributes
#     assert_redirected_to map_type_path(assigns(:map_type))
#   end

#   test "should destroy map_type" do
#     assert_difference('MapType.count', -1) do
#       delete :destroy, :id => @map_type.to_param
#     end

#     assert_redirected_to map_types_path
#   end
# end
