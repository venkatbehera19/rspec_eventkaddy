class AddRatingCountToSessionStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :session_statistics, :rating_count, :integer, :after => :average_rating
  end
end
