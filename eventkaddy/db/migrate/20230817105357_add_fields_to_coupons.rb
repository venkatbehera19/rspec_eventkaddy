class AddFieldsToCoupons < ActiveRecord::Migration[6.1]
  def change
    add_column :coupons, :amount, :decimal, precision: 6, scale: 2
    add_column :coupons, :start_date, :datetime
    add_column :coupons, :end_date, :datetime
    add_column :coupons, :max_usage, :integer
    add_column :coupons, :remaining_usage, :integer
    add_column :coupons, :is_member, :boolean
    add_column :coupons, :coupon_code, :string
    add_column :coupons, :event_id, :integer
    add_column :coupons, :product_id, :integer
  end
end
