class CreateDeviceAppImageSizes < ActiveRecord::Migration[4.2]
  def change
    create_table :device_app_image_sizes do |t|
      t.integer :device_type_id
      t.integer :app_image_type_id
      t.integer :app_image_size_id

      t.timestamps
    end
  end
end
