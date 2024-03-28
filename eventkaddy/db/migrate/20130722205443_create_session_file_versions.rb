class CreateSessionFileVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :session_file_versions do |t|

      t.integer :event_id
      t.integer :session_file_id
      t.integer :event_file_id
      t.integer :user_id
      t.boolean :final_version

      t.timestamps
    end
  end
end
