class AddIsDemoToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :is_demo, :boolean, :after => :event_id
  end
end
