class AddTagsSafeguardToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :tags_safeguard, :text
  end
end
