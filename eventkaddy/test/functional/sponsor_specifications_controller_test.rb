# require 'test_helper'

# class SponsorSpecificationsControllerTest < ActionController::TestCase
#   setup do
#     @sponsor_specification = sponsor_specifications(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:sponsor_specifications)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create sponsor_specification" do
#     assert_difference('SponsorSpecification.count') do
#       post :create, :sponsor_specification => @sponsor_specification.attributes
#     end

#     assert_redirected_to sponsor_specification_path(assigns(:sponsor_specification))
#   end

#   test "should show sponsor_specification" do
#     get :show, :id => @sponsor_specification.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @sponsor_specification.to_param
#     assert_response :success
#   end

#   test "should update sponsor_specification" do
#     put :update, :id => @sponsor_specification.to_param, :sponsor_specification => @sponsor_specification.attributes
#     assert_redirected_to sponsor_specification_path(assigns(:sponsor_specification))
#   end

#   test "should destroy sponsor_specification" do
#     assert_difference('SponsorSpecification.count', -1) do
#       delete :destroy, :id => @sponsor_specification.to_param
#     end

#     assert_redirected_to sponsor_specifications_path
#   end
# end
