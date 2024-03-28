class CreateRoomLayoutConfigurations < ActiveRecord::Migration[4.2]
  def change
    create_table :room_layout_configurations do |t|
      t.string :name

      t.timestamps
    end
  end
end
