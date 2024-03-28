class CreateHomeButtonGroups < ActiveRecord::Migration[4.2]
  def self.up
    create_table :home_button_groups do |t|
      t.integer :event_id
      t.integer :event_file_id
      t.string :name
      t.string :icon_button
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :home_button_groups
  end
end
