class CreateCouponProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :coupon_products do |t|
      t.integer :coupons, null: false, foreign_key: true
      t.integer :products, null: false, foreign_key: true

      t.timestamps
    end
  end
end
