class AddSpeakerNamestoSessions < ActiveRecord::Migration[4.2]
  def change
      add_column :sessions, :speaker_names, :text, after: :sanitized_title
  end
end
