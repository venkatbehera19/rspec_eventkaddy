# require 'test_helper'

# class UsersOrganizationsControllerTest < ActionController::TestCase
#   setup do
#     @users_organization = users_organizations(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:users_organizations)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create users_organization" do
#     assert_difference('UsersOrganization.count') do
#       post :create, :users_organization => @users_organization.attributes
#     end

#     assert_redirected_to users_organization_path(assigns(:users_organization))
#   end

#   test "should show users_organization" do
#     get :show, :id => @users_organization.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @users_organization.to_param
#     assert_response :success
#   end

#   test "should update users_organization" do
#     put :update, :id => @users_organization.to_param, :users_organization => @users_organization.attributes
#     assert_redirected_to users_organization_path(assigns(:users_organization))
#   end

#   test "should destroy users_organization" do
#     assert_difference('UsersOrganization.count', -1) do
#       delete :destroy, :id => @users_organization.to_param
#     end

#     assert_redirected_to users_organizations_path
#   end
# end
