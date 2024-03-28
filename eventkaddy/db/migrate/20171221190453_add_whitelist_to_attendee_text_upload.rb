class AddWhitelistToAttendeeTextUpload < ActiveRecord::Migration[4.2]
  def change
    add_column :attendee_text_uploads, :whitelist, :boolean, :after => :text
  end
end
