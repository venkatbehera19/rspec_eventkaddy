class CreateSessionsTrackowners < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions_trackowners do |t|
      t.integer :session_id
      t.integer :trackowner_id

      t.timestamps
    end
    add_index :sessions_trackowners, :session_id
    add_index :sessions_trackowners, :trackowner_id
  end
end
