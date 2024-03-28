class AddPublishToAttendeeSurveyResultsToSurveys < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :publish_to_attendee_survey_results, :boolean, :after => :survey_type_id
  end
end
