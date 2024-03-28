# require 'test_helper'

# class EnhancedListingsControllerTest < ActionController::TestCase
#   setup do
#     @enhanced_listing = enhanced_listings(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:enhanced_listings)
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create enhanced_listing" do
#     assert_difference('EnhancedListing.count') do
#       post :create, :enhanced_listing => @enhanced_listing.attributes
#     end

#     assert_redirected_to enhanced_listing_path(assigns(:enhanced_listing))
#   end

#   test "should show enhanced_listing" do
#     get :show, :id => @enhanced_listing.to_param
#     assert_response :success
#   end

#   test "should get edit" do
#     get :edit, :id => @enhanced_listing.to_param
#     assert_response :success
#   end

#   test "should update enhanced_listing" do
#     put :update, :id => @enhanced_listing.to_param, :enhanced_listing => @enhanced_listing.attributes
#     assert_redirected_to enhanced_listing_path(assigns(:enhanced_listing))
#   end

#   test "should destroy enhanced_listing" do
#     assert_difference('EnhancedListing.count', -1) do
#       delete :destroy, :id => @enhanced_listing.to_param
#     end

#     assert_redirected_to enhanced_listings_path
#   end
# end
