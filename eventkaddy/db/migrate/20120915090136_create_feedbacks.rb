class CreateFeedbacks < ActiveRecord::Migration[4.2]
  def change
    create_table :feedbacks do |t|
      t.integer :event_id
      t.integer :session_id
      t.integer :attendee_id
      t.integer :rating
      t.text :comment

      t.timestamps
    end
  end
end
