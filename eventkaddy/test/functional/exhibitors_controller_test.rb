# require 'test_helper'

# class ExhibitorsControllerTest < ActionController::TestCase
#   setup do
#     @exhibitor = exhibitors(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:exhibitors)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create exhibitor" do
#     assert_difference('Exhibitor.count') do
#       post :create, :exhibitor => @exhibitor.attributes
#     end

#     assert_redirected_to exhibitor_path(assigns(:exhibitor))
#   end

#   test "should show exhibitor" do
#     get :show, :id => @exhibitor.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @exhibitor.to_param
#     assert_response :success
#   end

#   test "should update exhibitor" do
#     put :update, :id => @exhibitor.to_param, :exhibitor => @exhibitor.attributes
#     assert_redirected_to exhibitor_path(assigns(:exhibitor))
#   end

#   test "should destroy exhibitor" do
#     assert_difference('Exhibitor.count', -1) do
#       delete :destroy, :id => @exhibitor.to_param
#     end

#     assert_redirected_to exhibitors_path
#   end
# end
