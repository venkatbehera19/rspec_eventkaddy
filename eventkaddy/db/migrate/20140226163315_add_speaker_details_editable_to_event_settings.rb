class AddSpeakerDetailsEditableToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :speaker_details_editable, :boolean
  end
end
