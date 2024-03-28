class CreateSessionRecommendations < ActiveRecord::Migration[4.2]
  def change
    create_table :session_recommendations do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :session_id
      t.string :session_code
      t.text :reason
      t.boolean :useful
      t.integer :recommendation_source_type_id
      t.integer :recommendation_persistence_type_id

      t.timestamps
    end
  end
end
