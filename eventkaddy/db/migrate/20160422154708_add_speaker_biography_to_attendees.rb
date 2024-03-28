class AddSpeakerBiographyToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :speaker_biography, :text
  end
end
