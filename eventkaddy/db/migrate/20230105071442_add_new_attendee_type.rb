class AddNewAttendeeType < ActiveRecord::Migration[6.1]
  def change
    AttendeeType.find_or_create_by(name: 'Exhibitor Lead Retrieval')
  end
end
