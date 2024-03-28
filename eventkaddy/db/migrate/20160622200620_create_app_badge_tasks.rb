class CreateAppBadgeTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :app_badge_tasks do |t|
      t.integer :event_id
      t.integer :app_badge_id
      t.integer :image_event_file_id
      t.string :alt_image_url
      t.string :name
      t.string :description
      t.text :details
      t.integer :position
      t.integer :app_badge_task_type_id
      t.integer :scavenger_hunt_id
      t.integer :scavenger_hunt_item_id
      t.integer :survey_id
      t.integer :points_per_action
      t.integer :points_to_complete
      t.integer :max_points_allotable

      t.timestamps
    end
  end
end
