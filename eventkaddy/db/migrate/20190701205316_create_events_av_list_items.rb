class CreateEventsAvListItems < ActiveRecord::Migration[4.2]
  def change
    create_table :events_av_list_items do |t|
      t.integer :event_id
      t.integer :av_list_item_id

      t.timestamps
    end
    add_index :events_av_list_items, :event_id
    add_index :events_av_list_items, :av_list_item_id
  end
end
