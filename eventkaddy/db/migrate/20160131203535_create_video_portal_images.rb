class CreateVideoPortalImages < ActiveRecord::Migration[4.2]
  def change
    create_table :video_portal_images do |t|
      t.integer :event_id
      t.integer :event_file_id
      t.integer :video_portal_image_type_id
      t.string :name

      t.timestamps
    end
    add_index :video_portal_images, :event_id
    add_index :video_portal_images, :event_file_id
    add_index :video_portal_images, :video_portal_image_type_id
  end
end
