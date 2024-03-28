class CreateCordovaReports < ActiveRecord::Migration[4.2]
  def change
    create_table :cordova_reports do |t|
      t.string :message
      t.string :filename
      t.integer :line_number
      t.integer :column_number
      t.text :stack
      t.string :local_time
      t.string :device
      t.boolean :reported_on_first_attempt
      t.integer :event_id
      t.integer :attendee_id
      t.string :attendee_email

      t.timestamps
    end
    add_index :cordova_reports, :event_id
    add_index :cordova_reports, :attendee_id
  end
end
