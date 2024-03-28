class AddSessionFileToEventSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :event_settings, :session_files, :boolean
  end
end
