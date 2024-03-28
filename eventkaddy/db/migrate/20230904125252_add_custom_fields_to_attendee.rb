class AddCustomFieldsToAttendee < ActiveRecord::Migration[6.1]
  def change
    add_column :attendees, :custom_fields, :text
  end
end
