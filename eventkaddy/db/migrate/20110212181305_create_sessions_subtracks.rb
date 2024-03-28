class CreateSessionsSubtracks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :sessions_subtracks do |t|
      t.integer :subtrack_id
      t.integer :session_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sessions_subtracks
  end
end
