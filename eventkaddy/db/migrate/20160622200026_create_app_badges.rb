class CreateAppBadges < ActiveRecord::Migration[4.2]
  def change
    create_table :app_badges do |t|
      t.integer :event_id
      t.integer :app_game_id
      t.integer :image_event_file_id
      t.string :alt_image_url
      t.string :name
      t.text :description
      t.text :details
      t.integer :position
      t.integer :min_badge_tasks_to_complete
      t.integer :min_points_to_complete

      t.timestamps
    end
  end
end
