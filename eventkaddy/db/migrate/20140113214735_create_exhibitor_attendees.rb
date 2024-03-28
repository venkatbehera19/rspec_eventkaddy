class CreateExhibitorAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_attendees do |t|
      t.integer :attendee_id
      t.integer :exhibitor_id
      t.string :flag
      t.text :company_name

      t.timestamps
    end
  end
end
