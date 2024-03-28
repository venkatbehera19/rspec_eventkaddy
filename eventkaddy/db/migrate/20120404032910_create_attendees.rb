class CreateAttendees < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees do |t|
      t.integer :event_id
      t.string :first_name
      t.string :last_name
      t.string :honor_prefix
      t.string :honor_suffix
      t.string :title
      t.string :company
      t.string :biography
      t.string :business_unit
      t.string :business_phone
      t.string :mobile_phone
      t.string :email
      t.string :photo_filename
      t.integer :photo_event_file_id      


      t.timestamps
    end
  end
end
