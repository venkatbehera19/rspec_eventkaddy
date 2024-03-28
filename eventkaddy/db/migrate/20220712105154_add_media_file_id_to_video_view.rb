class AddMediaFileIdToVideoView < ActiveRecord::Migration[6.1]
  def change
    add_column :video_views, :media_file_id, :integer
  end
end
