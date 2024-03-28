class CreateAttendeesExhibitorProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :attendees_exhibitor_products do |t|
      t.integer :event_id
      t.integer :attendee_id
      t.integer :exhibitor_product_id

      t.timestamps
    end
  end
end
