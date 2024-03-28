class CreateOrderItems < ActiveRecord::Migration[6.1]
  def change
    create_table :order_items do |t|
      t.integer :item_id
      t.integer :item_type
      t.string  :description
      t.decimal :price
      t.integer :quantity
      t.integer :product_image_id

      t.references :order
      t.timestamps
    end
  end
end
