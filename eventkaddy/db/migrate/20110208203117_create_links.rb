class CreateLinks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :links do |t|
      t.integer :session_id
      t.integer :event_file_id
      t.string :name
      t.integer :link_type_id
      t.string :filename

      t.timestamps
    end
  end

  def self.down
    drop_table :links
  end
end
