class CreateAppImageSizes < ActiveRecord::Migration[4.2]
  def change
    create_table :app_image_sizes do |t|
      t.decimal :image_width
      t.decimal :image_height

      t.timestamps
    end
  end
end
