class CreateRecommendationSourceTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :recommendation_source_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
