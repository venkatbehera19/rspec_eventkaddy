class AddSizeToCartItems < ActiveRecord::Migration[6.1]
  def change
    add_column :cart_items, :size, :string
  end
end
