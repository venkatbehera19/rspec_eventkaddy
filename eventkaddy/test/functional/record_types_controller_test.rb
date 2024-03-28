# require 'test_helper'

# class RecordTypesControllerTest < ActionController::TestCase
#   setup do
#     @record_type = record_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:record_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create record_type" do
#     assert_difference('RecordType.count') do
#       post :create, :record_type => @record_type.attributes
#     end

#     assert_redirected_to record_type_path(assigns(:record_type))
#   end

#   test "should show record_type" do
#     get :show, :id => @record_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @record_type.to_param
#     assert_response :success
#   end

#   test "should update record_type" do
#     put :update, :id => @record_type.to_param, :record_type => @record_type.attributes
#     assert_redirected_to record_type_path(assigns(:record_type))
#   end

#   test "should destroy record_type" do
#     assert_difference('RecordType.count', -1) do
#       delete :destroy, :id => @record_type.to_param
#     end

#     assert_redirected_to record_types_path
#   end
# end
