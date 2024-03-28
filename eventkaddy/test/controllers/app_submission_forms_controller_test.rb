require "test_helper"

class AppSubmissionFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @app_submission_form = app_submission_forms(:one)
  end

  test "should get index" do
    get app_submission_forms_url
    assert_response :success
  end

  test "should get new" do
    get new_app_submission_form_url
    assert_response :success
  end

  test "should create app_submission_form" do
    assert_difference('AppSubmissionForm.count') do
      post app_submission_forms_url, params: { app_submission_form: { app_form_type_id: @app_submission_form.app_form_type_id, app_name: @app_submission_form.app_name, description: @app_submission_form.description, event_id: @app_submission_form.event_id, keywords: @app_submission_form.keywords, subtitle: @app_submission_form.subtitle } }
    end

    assert_redirected_to app_submission_form_url(AppSubmissionForm.last)
  end

  test "should show app_submission_form" do
    get app_submission_form_url(@app_submission_form)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_submission_form_url(@app_submission_form)
    assert_response :success
  end

  test "should update app_submission_form" do
    patch app_submission_form_url(@app_submission_form), params: { app_submission_form: { app_form_type_id: @app_submission_form.app_form_type_id, app_name: @app_submission_form.app_name, description: @app_submission_form.description, event_id: @app_submission_form.event_id, keywords: @app_submission_form.keywords, subtitle: @app_submission_form.subtitle } }
    assert_redirected_to app_submission_form_url(@app_submission_form)
  end

  test "should destroy app_submission_form" do
    assert_difference('AppSubmissionForm.count', -1) do
      delete app_submission_form_url(@app_submission_form)
    end

    assert_redirected_to app_submission_forms_url
  end
end
