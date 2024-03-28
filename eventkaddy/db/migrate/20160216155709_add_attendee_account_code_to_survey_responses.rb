class AddAttendeeAccountCodeToSurveyResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_responses, :attendee_account_code, :string, :after => :attendee_id
  end
end
