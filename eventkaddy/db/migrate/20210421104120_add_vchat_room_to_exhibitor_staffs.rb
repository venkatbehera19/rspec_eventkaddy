class AddVchatRoomToExhibitorStaffs < ActiveRecord::Migration[4.2]
  def change
    add_column :exhibitor_staffs, :vchat_room, :string
  end
end
