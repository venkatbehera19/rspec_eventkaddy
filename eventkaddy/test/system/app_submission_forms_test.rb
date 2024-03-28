require "application_system_test_case"

class AppSubmissionFormsTest < ApplicationSystemTestCase
  setup do
    @app_submission_form = app_submission_forms(:one)
  end

  test "visiting the index" do
    visit app_submission_forms_url
    assert_selector "h1", text: "App Submission Forms"
  end

  test "creating a App submission form" do
    visit app_submission_forms_url
    click_on "New App Submission Form"

    fill_in "App form type", with: @app_submission_form.app_form_type_id
    fill_in "App name", with: @app_submission_form.app_name
    fill_in "Description", with: @app_submission_form.description
    fill_in "Event", with: @app_submission_form.event_id
    fill_in "Keywords", with: @app_submission_form.keywords
    fill_in "Subtitle", with: @app_submission_form.subtitle
    click_on "Create App submission form"

    assert_text "App submission form was successfully created"
    click_on "Back"
  end

  test "updating a App submission form" do
    visit app_submission_forms_url
    click_on "Edit", match: :first

    fill_in "App form type", with: @app_submission_form.app_form_type_id
    fill_in "App name", with: @app_submission_form.app_name
    fill_in "Description", with: @app_submission_form.description
    fill_in "Event", with: @app_submission_form.event_id
    fill_in "Keywords", with: @app_submission_form.keywords
    fill_in "Subtitle", with: @app_submission_form.subtitle
    click_on "Update App submission form"

    assert_text "App submission form was successfully updated"
    click_on "Back"
  end

  test "destroying a App submission form" do
    visit app_submission_forms_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "App submission form was successfully destroyed"
  end
end
