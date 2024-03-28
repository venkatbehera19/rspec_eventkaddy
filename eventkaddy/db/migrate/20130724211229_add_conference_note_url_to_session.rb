class AddConferenceNoteUrlToSession < ActiveRecord::Migration[4.2]
  def change
  	add_column :sessions, :session_file_urls, :text
  end
end
