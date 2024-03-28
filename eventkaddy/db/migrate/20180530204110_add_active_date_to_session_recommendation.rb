class AddActiveDateToSessionRecommendation < ActiveRecord::Migration[4.2]
  def change
    add_column :session_recommendations, :active_date, :date, :after => :recommendation_persistence_type_id
  end
end
