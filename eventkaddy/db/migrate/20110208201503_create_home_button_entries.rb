class CreateHomeButtonEntries < ActiveRecord::Migration[4.2]
  def self.up
    create_table :home_button_entries do |t|
      t.integer :group_id
      t.integer :event_file_id
      t.string :render_url
      t.string :name
      t.string :icon_entry
      t.text :content
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :home_button_entries
  end
end
