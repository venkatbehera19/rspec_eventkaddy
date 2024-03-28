class CreateUsersEvents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users_events do |t|
      t.integer :user_id
      t.integer :event_id

      t.timestamps
    end
  end

  def self.down
    drop_table :users_events
  end
end
