class CreateDiscountAllocation < ActiveRecord::Migration[6.1]
  def change
    create_table :discount_allocations do |t|
      t.decimal :amount, precision: 10, scale: 2, default: 0.0
      t.integer :complimentary_count, default: 0
      t.decimal :complimentary_amount, precision: 10, scale: 2, default: 0.0
      t.integer :discounted_count,    default: 0
      t.decimal :discounted_amount,    precision: 10, scale: 2, default: 0.0
      t.integer :full_count,          default: 0
      t.decimal :full_amount,          precision: 10, scale: 2, default: 0.0
      t.integer :user_id
      t.integer :event_id
      t.references :cart_item, foreign_key: true
      t.timestamps
    end
  end
end
