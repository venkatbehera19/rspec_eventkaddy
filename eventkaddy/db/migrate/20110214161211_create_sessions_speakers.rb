class CreateSessionsSpeakers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sessions_speakers do |t|
      t.integer :session_id
      t.integer :speaker_id
      t.boolean :is_moderator
      t.integer :speaker_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sessions_speakers
  end
end
