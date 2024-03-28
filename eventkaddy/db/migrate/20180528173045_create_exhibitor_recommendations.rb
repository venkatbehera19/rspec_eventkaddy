class CreateExhibitorRecommendations < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_recommendations do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :exhibitor_id
      t.string :exhibitor_code
      t.text :reason
      t.boolean :useful
      t.integer :recommendation_source_type_id
      t.integer :recommendation_persistence_type_id

      t.timestamps
    end
  end
end
