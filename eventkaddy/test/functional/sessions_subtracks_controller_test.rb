# require 'test_helper'

# class SessionsSubtracksControllerTest < ActionController::TestCase
#   setup do
#     @sessions_subtrack = sessions_subtracks(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:sessions_subtracks)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create sessions_subtrack" do
#     assert_difference('SessionsSubtrack.count') do
#       post :create, :sessions_subtrack => @sessions_subtrack.attributes
#     end

#     assert_redirected_to sessions_subtrack_path(assigns(:sessions_subtrack))
#   end

#   test "should show sessions_subtrack" do
#     get :show, :id => @sessions_subtrack.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @sessions_subtrack.to_param
#     assert_response :success
#   end

#   test "should update sessions_subtrack" do
#     put :update, :id => @sessions_subtrack.to_param, :sessions_subtrack => @sessions_subtrack.attributes
#     assert_redirected_to sessions_subtrack_path(assigns(:sessions_subtrack))
#   end

#   test "should destroy sessions_subtrack" do
#     assert_difference('SessionsSubtrack.count', -1) do
#       delete :destroy, :id => @sessions_subtrack.to_param
#     end

#     assert_redirected_to sessions_subtracks_path
#   end
# end
