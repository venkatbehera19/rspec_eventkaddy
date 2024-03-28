class AddCustomFields3toAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :custom_fields_3, :text
  end
end
