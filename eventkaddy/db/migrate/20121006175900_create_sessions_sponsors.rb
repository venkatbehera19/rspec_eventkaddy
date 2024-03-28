class CreateSessionsSponsors < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions_sponsors do |t|
      t.integer :session_id
      t.integer :sponsor_id

      t.timestamps
    end
  end
end
