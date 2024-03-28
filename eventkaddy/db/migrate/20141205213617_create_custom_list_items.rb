class CreateCustomListItems < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_list_items do |t|
      t.integer :event_id
      t.integer :custom_list_id
      t.text :content

      t.timestamps
    end
  end
end
