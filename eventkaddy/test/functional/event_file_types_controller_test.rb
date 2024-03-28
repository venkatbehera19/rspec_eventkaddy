# require 'test_helper'

# class EventFileTypesControllerTest < ActionController::TestCase
#   setup do
#     @event_file_type = event_file_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:event_file_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create event_file_type" do
#     assert_difference('EventFileType.count') do
#       post :create, :event_file_type => @event_file_type.attributes
#     end

#     assert_redirected_to event_file_type_path(assigns(:event_file_type))
#   end

#   test "should show event_file_type" do
#     get :show, :id => @event_file_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @event_file_type.to_param
#     assert_response :success
#   end

#   test "should update event_file_type" do
#     put :update, :id => @event_file_type.to_param, :event_file_type => @event_file_type.attributes
#     assert_redirected_to event_file_type_path(assigns(:event_file_type))
#   end

#   test "should destroy event_file_type" do
#     assert_difference('EventFileType.count', -1) do
#       delete :destroy, :id => @event_file_type.to_param
#     end

#     assert_redirected_to event_file_types_path
#   end
# end
