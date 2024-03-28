class AddBackGroundImagetoEventTickets < ActiveRecord::Migration[6.1]
  def change
    add_column :event_tickets, :background_image_id, :integer
  end
end
