class CreateAttendeesAppBadgeTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_app_badge_tasks do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :app_badge_task_id
      t.integer :app_badge_task_points_collected
      t.boolean :complete

      t.timestamps
    end
  end
end
