class CreateCouponCodeUsages < ActiveRecord::Migration[6.1]
  def change
    create_table :coupon_code_usages do |t|
      t.integer    :coupon_id ,null: false
      t.integer :user_id
      t.integer :registration_form_id

      t.timestamps
    end
  end
end
