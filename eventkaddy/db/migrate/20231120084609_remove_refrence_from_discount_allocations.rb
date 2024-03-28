class RemoveRefrenceFromDiscountAllocations < ActiveRecord::Migration[6.1]
  def change
    remove_reference :discount_allocations, :order_item, foreign_key: true
    remove_reference :discount_allocations, :cart_item, foreign_key: true
  end
end
