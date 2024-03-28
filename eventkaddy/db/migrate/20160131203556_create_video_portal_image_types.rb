class CreateVideoPortalImageTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :video_portal_image_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
