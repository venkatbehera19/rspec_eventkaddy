class AddIndexesToSessionRecommendations < ActiveRecord::Migration[4.2]
  def change
    add_index :session_recommendations, :attendee_id
    add_index :session_recommendations, :session_id
    add_index :session_recommendations, :session_code
  end
end
