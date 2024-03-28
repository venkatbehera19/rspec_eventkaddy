class AddMaximumDiscountedAndComplementartyToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :maximum_discount_staff, :integer
    add_column :products, :maximum_complimentary_staff, :integer
  end
end
