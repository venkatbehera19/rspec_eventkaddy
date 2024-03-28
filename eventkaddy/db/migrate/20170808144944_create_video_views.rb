class CreateVideoViews < ActiveRecord::Migration[4.2]
  def change
    create_table :video_views do |t|
      t.integer :event_id
      t.integer :session_id
      t.integer :attendee_id

      t.timestamps
    end
  end
end
