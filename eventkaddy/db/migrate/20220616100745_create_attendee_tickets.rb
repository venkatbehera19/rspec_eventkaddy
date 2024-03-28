class CreateAttendeeTickets < ActiveRecord::Migration[6.1]
  def change
    create_table :attendee_tickets do |t|
      t.integer :event_ticket_id
      t.integer :attendee_id
      
      t.timestamps
    end
  end
end
