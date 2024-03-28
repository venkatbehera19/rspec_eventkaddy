class AddSurveyResultsToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :survey_results, :text
  end
end
