class AddColumnsToDiscountAllocation < ActiveRecord::Migration[6.1]
  def change
    add_column :discount_allocations, :cart_item_id, :integer
    add_column :discount_allocations, :order_item_id, :integer
  end
end
