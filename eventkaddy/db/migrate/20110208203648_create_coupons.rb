class CreateCoupons < ActiveRecord::Migration[4.2]
  def self.up
    create_table :coupons do |t|
      t.integer :exhibitor_id
      t.string :coupon_name
      t.string :coupon_description
      t.string :coupon_link

      t.timestamps
    end
  end

  def self.down
    drop_table :coupons
  end
end
