class CreateSlots < ActiveRecord::Migration[6.1]
  def change
    create_table :slots do |t|
      t.integer :exhibitor_staff_id, null: false, index: true
      t.integer :attendee_id
      t.datetime :start_time
      t.datetime :end_time
      t.text :meeting_description
      t.string :organizer
      t.integer :stage

      t.timestamps
    end
  end
end
