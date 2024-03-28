class CreateNotifications < ActiveRecord::Migration[4.2]
  def self.up
    create_table :notifications do |t|
      t.integer :event_id
      t.string :name
      t.text :description
	 t.datetime :localtime	
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
