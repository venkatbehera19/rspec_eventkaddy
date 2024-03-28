class AddSessionIdToSurveyResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_responses, :session_id, :integer, :after => :attendee_id
    add_index :survey_responses, :session_id
  end
end
