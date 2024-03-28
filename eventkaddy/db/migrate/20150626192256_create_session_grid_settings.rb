class CreateSessionGridSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :session_grid_settings do |t|
      t.integer :event_id
      t.integer :user_id
      t.text :settings

      t.timestamps
    end
  end
end
