class AddSessionsNotesContentToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :session_notes_content, :string
  end
end
