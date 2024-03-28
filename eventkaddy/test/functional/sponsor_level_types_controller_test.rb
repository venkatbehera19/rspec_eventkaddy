# require 'test_helper'

# class SponsorLevelTypesControllerTest < ActionController::TestCase
#   setup do
#     @sponsor_level_type = sponsor_level_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:sponsor_level_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create sponsor_level_type" do
#     assert_difference('SponsorLevelType.count') do
#       post :create, :sponsor_level_type => @sponsor_level_type.attributes
#     end

#     assert_redirected_to sponsor_level_type_path(assigns(:sponsor_level_type))
#   end

#   test "should show sponsor_level_type" do
#     get :show, :id => @sponsor_level_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @sponsor_level_type.to_param
#     assert_response :success
#   end

#   test "should update sponsor_level_type" do
#     put :update, :id => @sponsor_level_type.to_param, :sponsor_level_type => @sponsor_level_type.attributes
#     assert_redirected_to sponsor_level_type_path(assigns(:sponsor_level_type))
#   end

#   test "should destroy sponsor_level_type" do
#     assert_difference('SponsorLevelType.count', -1) do
#       delete :destroy, :id => @sponsor_level_type.to_param
#     end

#     assert_redirected_to sponsor_level_types_path
#   end
# end
