class AddDiscountTypeToCoupons < ActiveRecord::Migration[6.1]
  def change
    add_column :coupons, :discount_type, :string
  end
end
