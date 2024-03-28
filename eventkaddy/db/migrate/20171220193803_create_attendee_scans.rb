class CreateAttendeeScans < ActiveRecord::Migration[4.2]
  def change
    create_table :attendee_scans do |t|
      t.integer :event_id
      t.integer :attendee_scan_type_id
      t.integer :initiating_attendee_id
      t.integer :target_attendee_id
      t.integer :session_id
      t.integer :exhibitor_id
      t.integer :location_mapping_id
      t.string  :session_code
      t.text    :exhibitor_name


      t.timestamps
    end
  end
end
