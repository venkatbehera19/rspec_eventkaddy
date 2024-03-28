class CreateRatings < ActiveRecord::Migration[4.2]
  def change
    create_table :ratings do |t|
      t.integer :value
      t.integer :session_id
      t.integer :attendee_id

      t.timestamps
    end
  end
end
