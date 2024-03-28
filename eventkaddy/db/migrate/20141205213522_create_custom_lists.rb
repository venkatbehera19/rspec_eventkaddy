class CreateCustomLists < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_lists do |t|
      t.integer :event_id
      t.integer :home_button_id
      t.integer :image_event_file_id
      t.string :name
      t.text :description
      t.integer :custom_list_type_id

      t.timestamps
    end
  end
end
