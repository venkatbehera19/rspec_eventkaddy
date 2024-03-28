class AddVideoDurationToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :video_duration, :time, :after => :video_thumbnail
  end
end
