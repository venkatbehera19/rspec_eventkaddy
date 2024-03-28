class CreateCartItems < ActiveRecord::Migration[6.1]
  def change
    create_table :cart_items do |t|
      t.integer :item_id
      t.string  :item_type
      t.integer :quantity, :default => 1

      t.references :cart
      t.timestamps
    end
  end
end
