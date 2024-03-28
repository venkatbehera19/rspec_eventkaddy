class AddIsMemberToAttendees < ActiveRecord::Migration[6.1]
  def change
    add_column :attendees, :is_member, :boolean, default: false
  end
end
