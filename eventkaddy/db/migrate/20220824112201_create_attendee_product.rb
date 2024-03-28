class CreateAttendeeProduct < ActiveRecord::Migration[6.1]
  def change
    create_table :attendee_products do |t|
      t.string :membership_id
      t.references :attendee
      t.references :product

      t.timestamps
    end
  end
end
