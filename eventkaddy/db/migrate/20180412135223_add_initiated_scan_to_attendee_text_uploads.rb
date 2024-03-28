class AddInitiatedScanToAttendeeTextUploads < ActiveRecord::Migration[4.2]
  def change
      add_column :attendee_text_uploads, :initiated_contact, :integer, after: :answered
  end
end
