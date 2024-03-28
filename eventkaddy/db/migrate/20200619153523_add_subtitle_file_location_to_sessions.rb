class AddSubtitleFileLocationToSessions < ActiveRecord::Migration[4.2]
  def change
     add_column :sessions, :subtitle_file_location, :text
  end
end
