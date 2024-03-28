class AddDefaultToRoomLayout < ActiveRecord::Migration[4.2]
  def change
  	add_column :room_layouts, :default, :boolean
  end
end
