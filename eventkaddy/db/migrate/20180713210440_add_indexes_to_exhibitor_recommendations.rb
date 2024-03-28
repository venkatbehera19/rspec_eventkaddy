class AddIndexesToExhibitorRecommendations < ActiveRecord::Migration[4.2]
  def change
    add_index :exhibitor_recommendations, :attendee_id
    add_index :exhibitor_recommendations, :exhibitor_id
    add_index :exhibitor_recommendations, :exhibitor_code
  end
end
