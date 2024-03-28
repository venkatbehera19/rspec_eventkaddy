class AddColumnsToAttendees < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :assignment, :string
    add_column :attendees, :validar_url, :string
    add_column :attendees, :publish, :string
    add_column :attendees, :twitter_url, :string
    add_column :attendees, :facebook_url, :string
    add_column :attendees, :linked_in, :string
  end
end
