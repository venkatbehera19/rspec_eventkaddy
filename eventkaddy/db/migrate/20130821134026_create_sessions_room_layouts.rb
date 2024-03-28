class CreateSessionsRoomLayouts < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions_room_layouts do |t|
      t.integer :event_id
      t.integer :session_id
      t.integer :room_layout_id

      t.timestamps
    end
  end
end
