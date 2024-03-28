# require 'test_helper'

# class SessionSpeakersControllerTest < ActionController::TestCase
#   setup do
#     @session_speaker = session_speakers(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:session_speakers)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create session_speaker" do
#     assert_difference('SessionSpeaker.count') do
#       post :create, :session_speaker => @session_speaker.attributes
#     end

#     assert_redirected_to session_speaker_path(assigns(:session_speaker))
#   end

#   test "should show session_speaker" do
#     get :show, :id => @session_speaker.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @session_speaker.to_param
#     assert_response :success
#   end

#   test "should update session_speaker" do
#     put :update, :id => @session_speaker.to_param, :session_speaker => @session_speaker.attributes
#     assert_redirected_to session_speaker_path(assigns(:session_speaker))
#   end

#   test "should destroy session_speaker" do
#     assert_difference('SessionSpeaker.count', -1) do
#       delete :destroy, :id => @session_speaker.to_param
#     end

#     assert_redirected_to session_speakers_path
#   end
# end
