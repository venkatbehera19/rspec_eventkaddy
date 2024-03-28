class AddAnsweredToAttendeeTextUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :attendee_text_uploads, :answered, :boolean, :after => :whitelist
  end
end
