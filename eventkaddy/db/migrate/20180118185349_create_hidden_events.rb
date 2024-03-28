class CreateHiddenEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :hidden_events do |t|
      t.integer :event_id
      t.integer :user_id

      t.timestamps
    end
  end
end
