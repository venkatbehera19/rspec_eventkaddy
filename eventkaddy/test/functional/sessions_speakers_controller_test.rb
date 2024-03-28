# require 'test_helper'

# class SessionsSpeakersControllerTest < ActionController::TestCase
#   setup do
#     @sessions_speaker = sessions_speakers(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:sessions_speakers)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create sessions_speaker" do
#     assert_difference('SessionsSpeaker.count') do
#       post :create, :sessions_speaker => @sessions_speaker.attributes
#     end

#     assert_redirected_to sessions_speaker_path(assigns(:sessions_speaker))
#   end

#   test "should show sessions_speaker" do
#     get :show, :id => @sessions_speaker.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @sessions_speaker.to_param
#     assert_response :success
#   end

#   test "should update sessions_speaker" do
#     put :update, :id => @sessions_speaker.to_param, :sessions_speaker => @sessions_speaker.attributes
#     assert_redirected_to sessions_speaker_path(assigns(:sessions_speaker))
#   end

#   test "should destroy sessions_speaker" do
#     assert_difference('SessionsSpeaker.count', -1) do
#       delete :destroy, :id => @sessions_speaker.to_param
#     end

#     assert_redirected_to sessions_speakers_path
#   end
# end
