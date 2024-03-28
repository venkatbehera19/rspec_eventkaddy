class AddSlugToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :slug, :binary, index: true, unique: true
  end
end
