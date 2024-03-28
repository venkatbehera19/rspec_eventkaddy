class CreateLocationMappingProductJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_table :location_mapping_products do |t|
      t.integer :product_id
      t.integer :location_mapping_id

      t.timestamps
    end
  end
end
