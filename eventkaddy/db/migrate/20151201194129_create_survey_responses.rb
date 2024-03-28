class CreateSurveyResponses < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_responses do |t|
      t.belongs_to :event
      t.belongs_to :attendee
      t.belongs_to :survey
      t.decimal :gps_location
      t.integer :time_taken

      t.timestamps
    end
    add_index :survey_responses, :event_id
    add_index :survey_responses, :attendee_id
    add_index :survey_responses, :survey_id
  end
end
