class AddTransactionToAttendeeProduct < ActiveRecord::Migration[6.1]
  def change
    add_reference :attendee_products, :transaction
  end
end
