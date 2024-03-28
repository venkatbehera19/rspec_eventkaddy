class CreateSpeakers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :speakers do |t|
      t.integer :event_id
      t.string :first_name
      t.string :last_name
      t.string :honor_prefix
      t.string :honor_suffix
      t.string :company
      t.text :biography
      t.string :photo_filename
      t.integer :photo_event_file_id
      t.string :email
      t.integer :speaker_type

      t.timestamps
    end
  end

  def self.down
    drop_table :speakers
  end
end
