# require 'test_helper'

# class LinkTypesControllerTest < ActionController::TestCase
#   setup do
#     @link_type = link_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:link_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create link_type" do
#     assert_difference('LinkType.count') do
#       post :create, :link_type => @link_type.attributes
#     end

#     assert_redirected_to link_type_path(assigns(:link_type))
#   end

#   test "should show link_type" do
#     get :show, :id => @link_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @link_type.to_param
#     assert_response :success
#   end

#   test "should update link_type" do
#     put :update, :id => @link_type.to_param, :link_type => @link_type.attributes
#     assert_redirected_to link_type_path(assigns(:link_type))
#   end

#   test "should destroy link_type" do
#     assert_difference('LinkType.count', -1) do
#       delete :destroy, :id => @link_type.to_param
#     end

#     assert_redirected_to link_types_path
#   end
# end
