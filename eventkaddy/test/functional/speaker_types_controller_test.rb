# require 'test_helper'

# class SpeakerTypesControllerTest < ActionController::TestCase
#   setup do
#     @speaker_type = speaker_types(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:speaker_types)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create speaker_type" do
#     assert_difference('SpeakerType.count') do
#       post :create, :speaker_type => @speaker_type.attributes
#     end

#     assert_redirected_to speaker_type_path(assigns(:speaker_type))
#   end

#   test "should show speaker_type" do
#     get :show, :id => @speaker_type.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @speaker_type.to_param
#     assert_response :success
#   end

#   test "should update speaker_type" do
#     put :update, :id => @speaker_type.to_param, :speaker_type => @speaker_type.attributes
#     assert_redirected_to speaker_type_path(assigns(:speaker_type))
#   end

#   test "should destroy speaker_type" do
#     assert_difference('SpeakerType.count', -1) do
#       delete :destroy, :id => @speaker_type.to_param
#     end

#     assert_redirected_to speaker_types_path
#   end
# end
