class AddPublishedVideotoSessions < ActiveRecord::Migration[4.2]
  def change
	add_column :sessions, :publish_video, :boolean
        add_column :sessions, :short_title, :string
        add_column :sessions, :admin_video_blocked, :boolean 
  end

end
