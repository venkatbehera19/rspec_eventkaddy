# require 'test_helper'

# class ExhibitorLinksControllerTest < ActionController::TestCase
#   setup do
#     @exhibitor_link = exhibitor_links(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:exhibitor_links)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create exhibitor_link" do
#     assert_difference('ExhibitorLink.count') do
#       post :create, :exhibitor_link => @exhibitor_link.attributes
#     end

#     assert_redirected_to exhibitor_link_path(assigns(:exhibitor_link))
#   end

#   test "should show exhibitor_link" do
#     get :show, :id => @exhibitor_link.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @exhibitor_link.to_param
#     assert_response :success
#   end

#   test "should update exhibitor_link" do
#     put :update, :id => @exhibitor_link.to_param, :exhibitor_link => @exhibitor_link.attributes
#     assert_redirected_to exhibitor_link_path(assigns(:exhibitor_link))
#   end

#   test "should destroy exhibitor_link" do
#     assert_difference('ExhibitorLink.count', -1) do
#       delete :destroy, :id => @exhibitor_link.to_param
#     end

#     assert_redirected_to exhibitor_links_path
#   end
# end
