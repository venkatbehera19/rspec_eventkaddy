class AddTargetAttendeeIdToSurveyResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_responses, :target_attendee_id, :integer, :after => :attendee_account_code
    add_index :survey_responses, :target_attendee_id
  end
end
