class CreateExhibitorProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :exhibitor_products do |t|
      t.integer :event_id
      t.integer :exhibitor_id
      t.integer :qr_code_id
      t.integer :product_image_id
      t.string :name
      t.text :description
      t.string :product_url
      t.string :youtube_url

      t.timestamps
    end
  end
end
