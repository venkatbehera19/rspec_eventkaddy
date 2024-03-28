class CreateEventTickets < ActiveRecord::Migration[6.1]
  def change
    create_table :event_tickets do |t|
      t.datetime :date
      t.datetime :start_time
      t.datetime :end_time
      t.text :location
      t.text :description
      t.integer :event_id
      t.integer :session_id

      t.timestamps
    end
  end
end
