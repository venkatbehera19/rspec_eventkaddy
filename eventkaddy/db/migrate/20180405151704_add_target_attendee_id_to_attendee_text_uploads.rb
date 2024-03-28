class AddTargetAttendeeIdToAttendeeTextUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :attendee_text_uploads, :target_attendee_id, :integer, after: :exhibitor_id
    add_column :attendee_text_uploads, :target_attendee_name, :string, after: :exhibitor_name
  end
end
