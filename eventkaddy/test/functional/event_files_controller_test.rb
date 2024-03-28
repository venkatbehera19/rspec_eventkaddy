# require 'test_helper'

# class EventFilesControllerTest < ActionController::TestCase
#   setup do
#     @event_file = event_files(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:event_files)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create event_file" do
#     assert_difference('EventFile.count') do
#       post :create, :event_file => @event_file.attributes
#     end

#     assert_redirected_to event_file_path(assigns(:event_file))
#   end

#   test "should show event_file" do
#     get :show, :id => @event_file.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @event_file.to_param
#     assert_response :success
#   end

#   test "should update event_file" do
#     put :update, :id => @event_file.to_param, :event_file => @event_file.attributes
#     assert_redirected_to event_file_path(assigns(:event_file))
#   end

#   test "should destroy event_file" do
#     assert_difference('EventFile.count', -1) do
#       delete :destroy, :id => @event_file.to_param
#     end

#     assert_redirected_to event_files_path
#   end
# end
