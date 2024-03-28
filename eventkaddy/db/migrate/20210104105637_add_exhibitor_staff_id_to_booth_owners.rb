class AddExhibitorStaffIdToBoothOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :booth_owners, :exhibitor_staff_id, :integer
  end
end
