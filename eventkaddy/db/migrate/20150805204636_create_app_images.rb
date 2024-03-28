class CreateAppImages < ActiveRecord::Migration[4.2]
  def change
    create_table :app_images do |t|
      t.integer :event_id
      t.integer :parent_id
      t.boolean :is_template
      t.integer :event_file_id
      t.integer :app_image_type_id
      t.integer :device_type_id
      t.integer :app_image_size_id
      t.string :name
      t.text :link

      t.timestamps
    end
  end
end
