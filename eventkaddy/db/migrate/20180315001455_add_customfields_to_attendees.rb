class AddCustomfieldsToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :custom_fields_1, :text
  end
end
