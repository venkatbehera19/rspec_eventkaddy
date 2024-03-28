class AddIndexesForSessionFilesAndRelated < ActiveRecord::Migration[4.2]
  def up
    add_index :session_file_versions, :session_file_id
    add_index :session_file_versions, :event_file_id
    add_index :session_file_versions, :user_id
    add_index :session_files, :session_id
  end

  def down
  end
end
