class AddMaxPointsPerActionToAppBadgeTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :app_badge_tasks, :max_points_per_action, :integer
  end
end
