class CreateAttendeesAppBadges < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_app_badges do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :app_badge_id
      t.integer :app_badge_points_collected
      t.integer :num_app_badge_tasks_completed
      t.boolean :complete
      t.boolean :prize_redeemed 

      t.timestamps
    end
  end
end
