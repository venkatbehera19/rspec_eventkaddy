class CreateEventFileTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :event_file_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :event_file_types
  end
end
