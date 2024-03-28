class AddEventIdToSlots < ActiveRecord::Migration[6.1]
  def change
    add_column :slots, :event_id, :integer
  end
end
