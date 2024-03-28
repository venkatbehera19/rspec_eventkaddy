# require 'test_helper'

# class HomeButtonEntriesControllerTest < ActionController::TestCase
#   setup do
#     @home_button_entry = home_button_entries(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:home_button_entries)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create home_button_entry" do
#     assert_difference('HomeButtonEntry.count') do
#       post :create, :home_button_entry => @home_button_entry.attributes
#     end

#     assert_redirected_to home_button_entry_path(assigns(:home_button_entry))
#   end

#   test "should show home_button_entry" do
#     get :show, :id => @home_button_entry.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @home_button_entry.to_param
#     assert_response :success
#   end

#   test "should update home_button_entry" do
#     put :update, :id => @home_button_entry.to_param, :home_button_entry => @home_button_entry.attributes
#     assert_redirected_to home_button_entry_path(assigns(:home_button_entry))
#   end

#   test "should destroy home_button_entry" do
#     assert_difference('HomeButtonEntry.count', -1) do
#       delete :destroy, :id => @home_button_entry.to_param
#     end

#     assert_redirected_to home_button_entries_path
#   end
# end
