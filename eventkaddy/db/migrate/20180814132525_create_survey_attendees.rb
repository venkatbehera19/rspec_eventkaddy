class CreateSurveyAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_attendees do |t|
      t.integer :event_id
      t.integer :survey_id
      t.integer :attendee_id

      t.timestamps
    end
  end
end
