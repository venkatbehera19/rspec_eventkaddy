class AddCouponToOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_column :order_items, :coupon_id, :integer
  end
end
