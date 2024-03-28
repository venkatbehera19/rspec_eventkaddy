class CreateRoomLayouts < ActiveRecord::Migration[4.2]
  def change
    create_table :room_layouts do |t|
      t.integer :event_id
      t.integer :event_file_id
      t.integer :room_layout_configuration_id
      t.string :title

      t.timestamps
    end
  end
end
