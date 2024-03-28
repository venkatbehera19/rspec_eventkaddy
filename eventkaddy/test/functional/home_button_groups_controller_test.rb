# require 'test_helper'

# class HomeButtonGroupsControllerTest < ActionController::TestCase
#   setup do
#     @home_button_group = home_button_groups(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:home_button_groups)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create home_button_group" do
#     assert_difference('HomeButtonGroup.count') do
#       post :create, :home_button_group => @home_button_group.attributes
#     end

#     assert_redirected_to home_button_group_path(assigns(:home_button_group))
#   end

#   test "should show home_button_group" do
#     get :show, :id => @home_button_group.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @home_button_group.to_param
#     assert_response :success
#   end

#   test "should update home_button_group" do
#     put :update, :id => @home_button_group.to_param, :home_button_group => @home_button_group.attributes
#     assert_redirected_to home_button_group_path(assigns(:home_button_group))
#   end

#   test "should destroy home_button_group" do
#     assert_difference('HomeButtonGroup.count', -1) do
#       delete :destroy, :id => @home_button_group.to_param
#     end

#     assert_redirected_to home_button_groups_path
#   end
# end
