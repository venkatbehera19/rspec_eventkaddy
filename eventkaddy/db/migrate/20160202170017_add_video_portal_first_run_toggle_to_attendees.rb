class AddVideoPortalFirstRunToggleToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :video_portal_first_run_toggle, :boolean, :after => :first_run_toggle
  end
end
