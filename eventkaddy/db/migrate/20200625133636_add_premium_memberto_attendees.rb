class AddPremiumMembertoAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :premium_member, :boolean
  end
end
