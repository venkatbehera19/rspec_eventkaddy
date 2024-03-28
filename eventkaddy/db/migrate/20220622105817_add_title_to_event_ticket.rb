class AddTitleToEventTicket < ActiveRecord::Migration[6.1]
  def change
    add_column :event_tickets, :title, :string
  end
end
