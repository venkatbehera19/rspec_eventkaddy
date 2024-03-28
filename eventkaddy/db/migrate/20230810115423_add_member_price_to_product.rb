class AddMemberPriceToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :member_price, :decimal, precision: 6, scale: 2
  end
end
