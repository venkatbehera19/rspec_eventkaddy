# require 'test_helper'

# class OrganizationEventsControllerTest < ActionController::TestCase
#   setup do
#     @organization_event = organization_events(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:organization_events)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create organization_event" do
#     assert_difference('OrganizationEvent.count') do
#       post :create, :organization_event => @organization_event.attributes
#     end

#     assert_redirected_to organization_event_path(assigns(:organization_event))
#   end

#   test "should show organization_event" do
#     get :show, :id => @organization_event.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @organization_event.to_param
#     assert_response :success
#   end

#   test "should update organization_event" do
#     put :update, :id => @organization_event.to_param, :organization_event => @organization_event.attributes
#     assert_redirected_to organization_event_path(assigns(:organization_event))
#   end

#   test "should destroy organization_event" do
#     assert_difference('OrganizationEvent.count', -1) do
#       delete :destroy, :id => @organization_event.to_param
#     end

#     assert_redirected_to organization_events_path
#   end
# end
