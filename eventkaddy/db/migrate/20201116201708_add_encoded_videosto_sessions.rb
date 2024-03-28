class AddEncodedVideostoSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :encoded_videos, :text
  end
end
