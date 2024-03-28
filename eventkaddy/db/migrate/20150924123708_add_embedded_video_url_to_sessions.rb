class AddEmbeddedVideoUrlToSessions < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :embedded_video_url, :string, :after => :record_type
  end
end
