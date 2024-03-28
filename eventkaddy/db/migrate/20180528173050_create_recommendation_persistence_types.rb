class CreateRecommendationPersistenceTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :recommendation_persistence_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
