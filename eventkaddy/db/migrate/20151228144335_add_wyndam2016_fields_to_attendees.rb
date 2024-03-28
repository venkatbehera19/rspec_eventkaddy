class AddWyndam2016FieldsToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :city, :string, :after => :mobile_phone
    add_column :attendees, :state, :string, :after => :mobile_phone
    add_column :attendees, :country, :string, :after => :mobile_phone
    add_column :attendees, :messaging, :boolean, :after => :attendee_type_id
  end
end
