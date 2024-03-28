class CreateTagsAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :tags_attendees do |t|
      t.integer :tag_id
      t.integer :attendee_id

      t.timestamps
    end
  end
end
