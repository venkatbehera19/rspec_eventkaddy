class AddCartItemRefernceInDiscountAllocations < ActiveRecord::Migration[6.1]
  def change
    add_reference :discount_allocations, :order_item, foreign_key: true
  end
end
