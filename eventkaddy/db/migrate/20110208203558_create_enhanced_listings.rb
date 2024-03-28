class CreateEnhancedListings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :enhanced_listings do |t|
      t.integer :exhibitor_id
      t.integer :event_file_id
      t.string :product_name
      t.string :product_image
      t.string :product_description
      t.string :product_link

      t.timestamps
    end
  end

  def self.down
    drop_table :enhanced_listings
  end
end
