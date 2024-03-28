class AddOrderInProductAndCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :order, :integer
    add_column :product_categories, :order, :integer
  end
end
