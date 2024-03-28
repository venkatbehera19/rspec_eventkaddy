class AddTempPhotoFilenameToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :temp_photo_filename, :string, :after => :notes_email_pending
  end
end
