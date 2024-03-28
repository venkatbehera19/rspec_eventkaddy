# require 'test_helper'

# class RecordCommentsControllerTest < ActionController::TestCase
#   setup do
#     @record_comment = record_comments(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:record_comments)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create record_comment" do
#     assert_difference('RecordComment.count') do
#       post :create, :record_comment => @record_comment.attributes
#     end

#     assert_redirected_to record_comment_path(assigns(:record_comment))
#   end

#   test "should show record_comment" do
#     get :show, :id => @record_comment.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @record_comment.to_param
#     assert_response :success
#   end

#   test "should update record_comment" do
#     put :update, :id => @record_comment.to_param, :record_comment => @record_comment.attributes
#     assert_redirected_to record_comment_path(assigns(:record_comment))
#   end

#   test "should destroy record_comment" do
#     assert_difference('RecordComment.count', -1) do
#       delete :destroy, :id => @record_comment.to_param
#     end

#     assert_redirected_to record_comments_path
#   end
# end
