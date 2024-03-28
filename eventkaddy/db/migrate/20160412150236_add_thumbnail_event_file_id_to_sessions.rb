class AddThumbnailEventFileIdToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :thumbnail_event_file_id, :integer, :after => :video_thumbnail
  end
end
