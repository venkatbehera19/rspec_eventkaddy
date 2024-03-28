class AddCouponAmountToOrderItems < ActiveRecord::Migration[6.1]
  def change
    add_column :order_items, :coupon_amount, :integer
  end
end
