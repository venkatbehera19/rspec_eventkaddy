class AddCustomFieldsColumntoAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :custom_fields_2, :text
  end
end
