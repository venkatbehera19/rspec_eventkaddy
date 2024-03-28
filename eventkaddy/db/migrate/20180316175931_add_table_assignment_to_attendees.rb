class AddTableAssignmentToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :table_assignment, :text
  end
end
