class AddActiveDateToExhibitorRecommendation < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitor_recommendations, :active_date, :date, :after => :recommendation_persistence_type_id
  end
end
