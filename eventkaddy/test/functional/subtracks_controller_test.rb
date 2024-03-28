# require 'test_helper'

# class SubtracksControllerTest < ActionController::TestCase
#   setup do
#     @subtrack = subtracks(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:subtracks)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create subtrack" do
#     assert_difference('Subtrack.count') do
#       post :create, :subtrack => @subtrack.attributes
#     end

#     assert_redirected_to subtrack_path(assigns(:subtrack))
#   end

#   test "should show subtrack" do
#     get :show, :id => @subtrack.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @subtrack.to_param
#     assert_response :success
#   end

#   test "should update subtrack" do
#     put :update, :id => @subtrack.to_param, :subtrack => @subtrack.attributes
#     assert_redirected_to subtrack_path(assigns(:subtrack))
#   end

#   test "should destroy subtrack" do
#     assert_difference('Subtrack.count', -1) do
#       delete :destroy, :id => @subtrack.to_param
#     end

#     assert_redirected_to subtracks_path
#   end
# end
