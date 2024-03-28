class CreateSessionStatistics < ActiveRecord::Migration[4.2]
  def change
    create_table :session_statistics do |t|
      t.integer :event_id
      t.integer :session_id
      t.float :average_rating
      t.integer :video_plays

      t.timestamps
    end
  end
end
