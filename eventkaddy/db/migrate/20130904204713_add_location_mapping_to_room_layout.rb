class AddLocationMappingToRoomLayout < ActiveRecord::Migration[4.2]
  def change
    	add_column :room_layouts, :location_mapping_id, :integer
  end
end
