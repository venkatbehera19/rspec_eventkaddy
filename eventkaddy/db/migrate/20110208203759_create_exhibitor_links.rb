class CreateExhibitorLinks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :exhibitor_links do |t|
      t.integer :exhibitor_id
      t.integer :event_file_id
      t.string :name
      t.string :url

      t.timestamps
    end
  end

  def self.down
    drop_table :exhibitor_links
  end
end
