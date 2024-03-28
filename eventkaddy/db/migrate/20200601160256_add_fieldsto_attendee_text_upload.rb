class AddFieldstoAttendeeTextUpload < ActiveRecord::Migration[4.2]
  def change
    add_column :attendee_text_uploads, :answer, :text, after: :text
    add_column :attendee_text_uploads, :rank, :integer, after: :answer
  end
end
